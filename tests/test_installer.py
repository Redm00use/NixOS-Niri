import contextlib
import io
import itertools
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from scripts.installer import cli, common, disk, meta


class InstallerTests(unittest.TestCase):
    def args(self, *extra):
        with patch.object(sys, 'argv', ['install.py', '--mode', 'config', '--host', 'mypc', '--user', 'me', '--gpu', 'vm', '--yes', *extra]):
            return cli.parse_args()

    def test_yes_never_prompts(self):
        with patch('builtins.input', side_effect=AssertionError('unexpected prompt')):
            answers = cli.collect_answers(self.args('--mode', 'live', '--disk', '/dev/nvme0n1'))
        self.assertFalse(answers['luks'])
        self.assertFalse(answers['separate_home'])
        self.assertEqual(answers['swap_size_gib'], 8)

    def test_missing_disk_fails_before_prompt(self):
        with patch('builtins.input', side_effect=AssertionError('unexpected prompt')):
            with self.assertRaisesRegex(ValueError, '--disk'):
                cli.collect_answers(self.args('--mode', 'live'))

    def test_dry_run_has_no_writes_or_commands(self):
        for mode in ['config', 'live']:
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as tmp:
                export = Path(tmp) / 'answers.json'
                args = self.args('--mode', mode, '--disk', '/dev/sda', '--dry-run', '--luks', '--export-json', str(export))
                with patch.object(cli, 'parse_args', return_value=args), \
                     patch.object(cli, 'ensure_host_files_for', side_effect=AssertionError('write')), \
                     patch.object(cli, 'backup_host_dir', side_effect=AssertionError('backup')), \
                     patch.object(cli, 'preflight_checks', side_effect=AssertionError('preflight')), \
                     patch.object(cli, 'validate_disk', side_effect=AssertionError('disk')), \
                     patch.object(cli, 'log_file', side_effect=AssertionError('log')), \
                     patch.object(cli, 'prompt_passphrase', side_effect=AssertionError('password')), \
                     contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(cli.main(), 0)
                self.assertFalse(export.exists())

    def test_json_validation(self):
        invalid = [[], {'mode': 'oops'}, {'fs': 'xfs'}, {'luks': 'false'},
                   {'swap_size_gib': -1}, {'home_size_gib': True}, {'gpu': []},
                   {'timezone': '../etc'}, {'locale': '${bad}'}, {'user': 4},
                   {'luks_passphrase': 'secret'}]
        for value in invalid:
            with self.subTest(value=value), self.assertRaises(ValueError):
                meta.validate_answers(value)

    def test_import_false_zero_and_cli_overrides(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / 'answers.json'
            source.write_text(json.dumps({'mode': 'live', 'disk': '/dev/sda', 'luks': True, 'separate_home': False, 'home_size_gib': 0, 'swap_size_gib': 0}))
            answers = cli.collect_answers(self.args('--mode', 'live', '--import-json', str(source), '--no-luks'))
            self.assertFalse(answers['luks'])
            self.assertEqual(answers['swap_size_gib'], 0)
            self.assertFalse(answers['separate_home'])

    def test_cancel_does_not_create_host(self):
        args = self.args()
        args.yes = False
        answers = {'mode': 'config', 'host': 'mypc', 'user': 'me'}
        with patch.object(cli, 'parse_args', return_value=args), \
             patch.object(cli, 'collect_answers', return_value=answers), \
             patch.object(cli, 'ask', return_value='n'), \
             patch.object(cli, 'backup_host_dir', side_effect=AssertionError('backup')), \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(cli.main(), 1)

    def test_meta_preserves_existing_storage_and_custom_fields(self):
        with tempfile.TemporaryDirectory() as tmp:
            host = Path(tmp)
            source = '{ luksEnabled = true; swapUuid = "old"; system = "aarch64-linux"; initialPassword = "custom"; }\n'
            (host / 'meta.nix').write_text(source)
            meta.write_meta('me', 'mypc', 'vm', 'desktop', 'UTC', 'en_US.UTF-8', host_dir=host, preserve_storage=True)
            text = (host / 'meta.nix').read_text()
            self.assertIn(source.rstrip(), text)
            self.assertNotIn('luksEnabled = false', text)
            self.assertIn('hostName = "mypc";', text)
        self.assertEqual(meta.nix_value('${bad}"'), '"\\${bad}\\\""')

    def test_config_export_and_host_generation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            exported = root / 'answers.json'
            args = self.args('--export-json', str(exported))
            template = meta.TEMPLATE_HOST_DIR
            with patch.object(cli, 'parse_args', return_value=args), \
                 patch.object(meta, 'REPO_ROOT', root), \
                 patch.object(meta, 'BACKUP_DIR', root / '.installer-backups'), \
                 contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(cli.main(), 0)
                hardware = root / 'hosts/mypc/hardware-configuration.nix'
                self.assertEqual(hardware.read_text(), (template / 'hardware-configuration.nix').read_text())
                self.assertEqual(json.loads(exported.read_text())['mode'], 'config')
                self.assertEqual(cli.main(), 0)
                self.assertEqual(len(list((root / '.installer-backups').iterdir())), 1)

    def test_partition_names(self):
        for name, expected in [('sda', 'sda2'), ('nvme0n1', 'nvme0n1p2'), ('mmcblk0', 'mmcblk0p2'), ('loop0', 'loop0p2')]:
            self.assertEqual(common.partition_suffix('/dev/' + name, 2), '/dev/' + expected)

    def test_partition_matrix(self):
        for fs, home, swap, luks in itertools.product(['ext4', 'btrfs'], [False, True], [0, 4], [False, True]):
            with self.subTest(fs=fs, home=home, swap=swap, luks=luks):
                commands = []
                resources = disk.InstallResources()
                with patch.object(disk, 'run', side_effect=lambda command, **kw: commands.append(command)), \
                     patch.object(disk, 'wait_for_device'), patch.object(Path, 'mkdir'):
                    disk.format_and_mount('/dev/nvme0n1', fs, home, 10 if home else 0, swap, luks, 'secret' if luks else None, resources=resources)
                rootnum = 2 + bool(swap) + home
                rootdev = '/dev/mapper/cryptroot' if luks else f'/dev/nvme0n1p{rootnum}'
                self.assertTrue(any(c[0] == 'mkfs.' + fs and c[-1] == rootdev for c in commands))
                self.assertIn(['mount', '/dev/nvme0n1p1', '/mnt/boot'], commands)
                self.assertTrue(resources.root_mounted)
                self.assertEqual(resources.crypt_open, luks)
                self.assertEqual(resources.swap_device, '/dev/nvme0n1p2' if swap else None)
                self.assertFalse(any('secret' in c for c in commands))
                if fs == 'btrfs' and not home:
                    self.assertIn(['mount', '-o', 'subvol=@home', rootdev, '/mnt/home'], commands)

    def test_cleanup_is_scoped(self):
        with patch.object(disk, 'run_quiet', return_value=True) as run:
            disk.cleanup_mounts(disk.InstallResources())
            run.assert_not_called()
            disk.cleanup_mounts(disk.InstallResources(True, '/dev/sda2', True))
            self.assertEqual([c.args[0] for c in run.call_args_list], [
                ['umount', '-R', '/mnt'], ['swapoff', '/dev/sda2'], ['cryptsetup', 'close', 'cryptroot']])

    def test_failed_unmount_does_not_close_mapper(self):
        with patch.object(disk, 'run_quiet', return_value=False) as run, contextlib.redirect_stdout(io.StringIO()):
            disk.cleanup_mounts(disk.InstallResources(True, None, True))
            run.assert_called_once_with(['umount', '-R', '/mnt'])

    def test_failure_at_every_disk_command_cleans_only_acquired_resources(self):
        with patch.object(disk, 'run') as run, patch.object(disk, 'wait_for_device'), patch.object(Path, 'mkdir'):
            disk.format_and_mount('/dev/sda', 'btrfs', False, 0, 4, True, 'secret', resources=disk.InstallResources())
            count = run.call_count
        for index in range(count):
            resources = disk.InstallResources()
            with self.subTest(command=index), patch.object(disk, 'run', side_effect=[None] * index + [RuntimeError('failure')]), \
                 patch.object(disk, 'wait_for_device'), patch.object(Path, 'mkdir'):
                with self.assertRaises(RuntimeError):
                    disk.format_and_mount('/dev/sda', 'btrfs', False, 0, 4, True, 'secret', resources=resources)
            expected = []
            if resources.root_mounted:
                expected.append(['umount', '-R', '/mnt'])
            if resources.swap_device:
                expected.append(['swapoff', resources.swap_device])
            if resources.crypt_open:
                expected.append(['cryptsetup', 'close', 'cryptroot'])
            with patch.object(disk, 'run_quiet', return_value=True) as cleanup:
                disk.cleanup_mounts(resources)
            self.assertEqual([c.args[0] for c in cleanup.call_args_list], expected)

    def test_missing_uuid_is_error(self):
        with patch.object(disk, 'blkid_value', return_value=None):
            for swap, luks in [(0, True), (4, False)]:
                with self.assertRaises(RuntimeError):
                    disk.capture_layout_ids('/dev/sda', False, swap, luks)

    def test_hardware_does_not_inherit_live_swap(self):
        hardware = '{\n  swapDevices = [\n    { device = "/dev/zram0"; }\n  ];\n  other = true;\n}\n'
        for uuid in [None, 'target-uuid']:
            with tempfile.TemporaryDirectory() as tmp, patch.object(Path, 'read_text', return_value=hardware):
                target = Path(tmp) / 'hardware.nix'
                disk.copy_hardware_config(target, uuid)
                with target.open() as handle:
                    content = handle.read()
                self.assertNotIn('zram', content)
                self.assertIn('other = true', content)
                if uuid:
                    self.assertIn('/dev/disk/by-uuid/target-uuid', content)

    def test_install_uses_path_flake_and_preserves_symlinks(self):
        with patch.object(Path, 'exists', return_value=False), patch.object(disk.shutil, 'copytree') as copy, \
             patch.object(disk, 'run') as run, contextlib.redirect_stdout(io.StringIO()):
            disk.install_system('mypc')
        self.assertTrue(copy.call_args.kwargs['symlinks'])
        self.assertIn('path:/mnt/etc/nixos/nixdots#mypc', run.call_args.args[0])
        ignored = copy.call_args.kwargs['ignore']('', ['.git', 'flake.nix'])
        self.assertIn('.git', ignored)
        self.assertNotIn('flake.nix', ignored)

    def test_live_interrupt_runs_cleanup(self):
        args = self.args('--mode', 'live', '--disk', '/dev/sda')
        with tempfile.TemporaryDirectory() as tmp, contextlib.ExitStack() as stack:
            for name in ['require_root', 'preflight_checks', 'confirm_disk_name', 'backup_host_dir']:
                stack.enter_context(patch.object(cli, name))
            stack.enter_context(patch.object(cli, 'parse_args', return_value=args))
            stack.enter_context(patch.object(cli, 'validate_disk', return_value='/dev/sda'))
            stack.enter_context(patch.object(cli, 'ensure_host_files_for', return_value=(Path(tmp), None, Path(tmp) / 'hardware.nix')))
            stack.enter_context(patch.object(cli, 'format_and_mount', side_effect=KeyboardInterrupt))
            cleanup = stack.enter_context(patch.object(cli, 'cleanup_mounts'))
            stack.enter_context(contextlib.redirect_stdout(io.StringIO()))
            self.assertEqual(cli.main(), 130)
            cleanup.assert_called_once()

    def test_disk_validation(self):
        base = {'name': '/dev/sda', 'type': 'disk', 'size': 128 * 1024**3, 'ro': False, 'mountpoints': [None]}
        cases = [({}, True), ({'type': 'part'}, False), ({'ro': True}, False),
                 ({'mountpoints': ['/']}, False), ({'size': 1024**3}, False),
                 ({'children': [{'name': '/dev/sda1', 'type': 'part', 'mountpoints': ['[SWAP]']}]}, False),
                 ({'children': [{'name': '/dev/dm-0', 'type': 'crypt'}]}, False)]
        for changes, valid in cases:
            payload = json.dumps({'blockdevices': [{**base, **changes}]})
            with self.subTest(changes=changes), patch.object(Path, 'is_dir', return_value=True), \
                 patch.object(Path, 'resolve', return_value=Path('/dev/sda')), \
                 patch.object(Path, 'is_block_device', return_value=True), \
                 patch.object(Path, 'exists', return_value=False), \
                 patch.object(Path, 'read_text', return_value=''), \
                 patch.object(disk, 'subprocess_output', return_value=payload):
                if valid:
                    self.assertEqual(disk.validate_disk('/dev/disk/by-id/test', 0, 4, False), '/dev/sda')
                else:
                    with self.assertRaises(ValueError):
                        disk.validate_disk('/dev/sda', 0, 4, False)


if __name__ == '__main__':
    unittest.main()
