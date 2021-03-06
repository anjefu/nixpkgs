{ stdenv, lib, fetchurl, hostPlatform }:
rec {

  luajit = luajit_2_1;

  luajit_2_0 = generic {
    version = "2.0.5";
    isStable = true;
    sha256 = "0yg9q4q6v028bgh85317ykc9whgxgysp76qzaqgq55y6jy11yjw7";
    meta = genericMeta // {
      platforms = lib.filter (p: p != "aarch64-linux") genericMeta.platforms;
    };
  };

  luajit_2_1 = generic {
    version = "2.1.0-beta3";
    isStable = false;
    sha256 = "1hyrhpkwjqsv54hnnx4cl8vk44h9d6c9w0fz1jfjz00w255y7lhs";
  };

  genericMeta = with stdenv.lib; {
    description = "High-performance JIT compiler for Lua 5.1";
    homepage    = http://luajit.org;
    license     = licenses.mit;
    platforms   = platforms.linux ++ platforms.darwin;
    maintainers = with maintainers; [ thoughtpolice smironov vcunat andir ];
  };

  generic =
    { version, sha256 ? null, isStable
    , name ? "luajit-${version}"
    , src ?
      (fetchurl {
        url = "http://luajit.org/download/LuaJIT-${version}.tar.gz";
        inherit sha256;
      })
    , meta ? genericMeta
    }:

    stdenv.mkDerivation rec {
      inherit name version src meta;

      luaversion = "5.1";

      patchPhase = ''
        substituteInPlace Makefile \
          --replace /usr/local "$out"

        substituteInPlace src/Makefile --replace gcc cc
      '' + stdenv.lib.optionalString (stdenv.cc.libc != null)
      ''
        substituteInPlace Makefile \
          --replace ldconfig ${stdenv.cc.libc.bin or stdenv.cc.libc}/bin/ldconfig
      '';

      configurePhase = false;

      buildFlags = [ "amalg" ]; # Build highly optimized version
      enableParallelBuilding = true;

      installPhase   = ''
        make install PREFIX="$out"
        ( cd "$out/include"; ln -s luajit-*/* . )
        ln -s "$out"/bin/luajit-* "$out"/bin/lua
      ''
        + stdenv.lib.optionalString (!isStable)
          ''
            ln -s "$out"/bin/luajit-* "$out"/bin/luajit
          '';
    };
}
