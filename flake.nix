{
  description = "Development shell for Common Lisp CFFI bindings to libmpv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (import nixpkgs { inherit system; })
        );
    in
    {
      devShells = forAllSystems (
        pkgs:
        let
          libPath = pkgs.lib.makeLibraryPath [
            pkgs.mpv
            pkgs.libffi
          ];
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.roswell
              pkgs.sbcl
              pkgs.sbclPackages.cffi
              pkgs.mpv
              pkgs.libffi
              pkgs.pkg-config
            ];

            shellHook = ''
              export LD_LIBRARY_PATH="${libPath}:''${LD_LIBRARY_PATH:-}"
              export DYLD_LIBRARY_PATH="${libPath}:''${DYLD_LIBRARY_PATH:-}"
              export CL_SOURCE_REGISTRY="$PWD//:''${CL_SOURCE_REGISTRY:-}"

              echo "Common Lisp dev shell: roswell, SBCL, CFFI, libmpv"
            '';
          };
        }
      );
    };
}
