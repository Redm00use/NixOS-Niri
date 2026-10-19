import contextlib
import io
import itertools
from pathlib import Path
import unittest
from unittest.mock import patch
from scripts.installer import cli, disk, meta

class LvmTests(unittest.TestCase):
    def test_lvm_matrix_and_cleanup(self):
        for fs,home,swap,luks in itertools.product(['ext4','btrfs'],[False,True],[0,4],[False,True]):
            with self.subTest(fs=fs,home=home,swap=swap,luks=luks):
                commands=[];r=disk.InstallResources()
                with patch.object(disk,'run',side_effect=lambda c,**kw:commands.append(c)), patch.object(disk,'check_lvm_available'), patch.object(disk,'wait_for_device'), patch.object(Path,'mkdir'):
                    disk.format_and_mount('/dev/nvme0n1',fs,home,10 if home else 0,swap,luks,'secret' if luks else None,resources=r,lvm_enabled=True)
                self.assertEqual(r.lvm_vg,'nixdots')
                self.assertIn(['vgcreate','nixdots','/dev/mapper/cryptroot' if luks else '/dev/nvme0n1p2'],commands)
                self.assertTrue(any(c[0]=='mkfs.'+fs and c[-1]=='/dev/nixdots/root' for c in commands))
                self.assertEqual(r.swap_device,'/dev/nixdots/swap' if swap else None)
                self.assertEqual(any(c[0]=='lvcreate' and 'home' in c for c in commands),home)
                self.assertFalse(any('secret' in c for c in commands))
                with patch.object(disk,'run_quiet',return_value=True) as cleanup:
                    disk.cleanup_mounts(r)
                closed=[c.args[0] for c in cleanup.call_args_list]
                self.assertIn(['vgchange','--activate','n','nixdots'],closed)
                if luks:self.assertEqual(closed[-1],['cryptsetup','close','cryptroot'])
    def test_vg_collision_stops_before_wipe(self):
        with patch.object(disk,'subprocess_output',return_value=' other\n nixdots\n'), patch.object(disk,'run') as run:
            with self.assertRaises(ValueError):
                disk.format_and_mount('/dev/sda','ext4',False,0,0,False,None,resources=disk.InstallResources(),lvm_enabled=True)
            run.assert_not_called()
    def test_failed_unmount_or_swap_preserves_lvm_and_crypto(self):
        for mounted,swap in [(True,None),(False,'/dev/nixdots/swap')]:
            r=disk.InstallResources(mounted,swap,True,'nixdots')
            with patch.object(disk,'run_quiet',return_value=False) as run,contextlib.redirect_stdout(io.StringIO()):
                disk.cleanup_mounts(r)
            self.assertFalse(any(c.args[0][0] in ['vgchange','cryptsetup'] for c in run.call_args_list))
    def test_ids_use_pv_for_luks_and_lv_for_swap(self):
        with patch.object(disk,'blkid_value',side_effect=['pv-partuuid','swap-uuid']) as read:
            self.assertEqual(disk.capture_layout_ids('/dev/sda',True,4,True,True),('pv-partuuid','swap-uuid'))
        self.assertEqual([c.args for c in read.call_args_list],[('/dev/sda2','PARTUUID'),('/dev/nixdots/swap','UUID')])
    def test_every_lvm_failure_can_release_acquired_resources(self):
        with patch.object(disk,'run') as run,patch.object(disk,'check_lvm_available'),patch.object(disk,'wait_for_device'),patch.object(Path,'mkdir'):
            disk.format_and_mount('/dev/sda','btrfs',True,10,4,True,'secret',resources=disk.InstallResources(),lvm_enabled=True)
            count=run.call_count
        for i in range(count):
            r=disk.InstallResources()
            with patch.object(disk,'run',side_effect=[None]*i+[RuntimeError('fail')]),patch.object(disk,'check_lvm_available'),patch.object(disk,'wait_for_device'),patch.object(Path,'mkdir'):
                with self.assertRaises(RuntimeError):disk.format_and_mount('/dev/sda','btrfs',True,10,4,True,'secret',resources=r,lvm_enabled=True)
            with patch.object(disk,'run_quiet',return_value=True):disk.cleanup_mounts(r)
            self.assertEqual(r,disk.InstallResources())
    def test_json_lvm_is_boolean_and_sizes_have_no_fixed_cap(self):
        meta.validate_answers({'lvm':True,'swap_size_gib':512,'separate_home':True,'home_size_gib':1000})
        with self.assertRaises(ValueError):meta.validate_answers({'lvm':'yes'})

class LvmAnswerTests(unittest.TestCase):
    def test_no_home_resets_imported_size(self):
        import json,sys,tempfile
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'answers.json'
            p.write_text(json.dumps({'mode':'live','host':'test','user':'tester','gpu':'vm','disk':'/dev/sda','lvm':True,'separate_home':True,'home_size_gib':100,'swap_size_gib':48}))
            with patch.object(sys,'argv',['install.py','--import-json',str(p),'--no-separate-home','--yes']):
                answers=cli.collect_answers(cli.parse_args())
        self.assertTrue(answers['lvm']);self.assertFalse(answers['separate_home'])
        self.assertEqual(answers['home_size_gib'],0);self.assertEqual(answers['swap_size_gib'],48)
