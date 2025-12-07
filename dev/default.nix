{
  pkgs,
  unstable,
  mynvim,
  ...
}:
{
  extraPackages = with pkgs; [
    mynvim.packages.${pkgs.system}.nvim
    vscode-fhs
    unstable.dbeaver-bin
    unstable.github-copilot-cli
    lazygit
    gh
    delta
    gcc
    gnumake
    lazydocker
    fd
    jq
    ripgrep
    insomnia
    # LSPs
    emmet-ls
    bash-language-server
    lua-language-server
    clang-tools
    nixd
    # Formatters
    nixfmt-rfc-style
    stylua
    shfmt
    nodePackages.prettier
  ];

  devShells = {
    php = pkgs.mkShell {
      buildInputs = with pkgs; [
        php
        php.packages.composer
        laravel
        nodePackages.intelephense
        (callPackage ../pkgs/php-cs-fixer/package.nix { })
        tailwindcss-language-server
      ];
    };

    go = pkgs.mkShell {
      buildInputs = with pkgs; [
        go
        golangci-lint
        gopls
      ];
    };

    node = pkgs.mkShell {
      buildInputs = with pkgs; [
        nodejs
        bun
        nodePackages.typescript-language-server
        nodePackages.vscode-langservers-extracted
        nodePackages.eslint_d
        unstable.vue-language-server
        tailwindcss-language-server
        nodePackages.live-server
      ];
    };

    python = pkgs.mkShell {
      buildInputs = with pkgs; [
        python313
        black
        pyright
      ];
    };
  };
}
