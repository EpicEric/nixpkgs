{
  bash,
  buildNpmPackage,
  fetchFromGitHub,
  lib,
  makeBinaryWrapper,
  nodejs_24,
  prisma_6,
  withDatabaseProvider ? "postgresql",
  withMigrationsFolder ?
    if withDatabaseProvider == "psql_bouncer" then
      "postgresql-migrations"
    else
      "${withDatabaseProvider}-migrations",
}:
buildNpmPackage (finalAttrs: {
  pname = "evolution-api";
  version = "2.3.7";

  src = fetchFromGitHub {
    owner = "EvolutionAPI";
    repo = "evolution-api";
    tag = finalAttrs.version;
    hash = "sha256-AF+M9T3Q14Yhi2ObaZIvFXeiIwLLvQRGTK6EnwDJavE=";
  };

  nodejs = nodejs_24;
  npmDepsHash = "sha256-L/7WBrMa9gYlD9DOJYm/4n42IjNniTTBoncNKrlkers=";
  makeCacheWritable = true;

  nativeBuildInputs = [
    makeBinaryWrapper
    prisma_6
  ];

  buildPhase = ''
    runHook preBuild

    prisma generate --schema ./prisma/${withDatabaseProvider}-schema.prisma
    cp -r ./prisma/${withMigrationsFolder} ./prisma/migrations
    npm run build

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/share/evolution-api $out/bin

    cp package*.json $out/share/evolution-api/
    cp -r dist $out/share/evolution-api/
    cp -r node_modules $out/share/evolution-api/
    cp -r prisma $out/share/evolution-api/

    cat > $out/bin/evolution-api <<EOF
    #!${bash}/bin/bash
    cd $out/share/evolution-api
    ${lib.getExe prisma_6} migrate deploy --schema ./prisma/${withDatabaseProvider}-schema.prisma
    ${lib.getExe nodejs_24} ./dist/main.js
    EOF
    chmod +x $out/bin/evolution-api
  '';

  meta = {
    description = "WhatsApp controller API supporting multiple messaging services and integrations";
    homepage = "https://github.com/EvolutionAPI/evolution-api";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    changelog = "https://github.com/EvolutionAPI/evolution-api/releases/tag/${finalAttrs.version}";
    mainProgram = "evolution-api";
    maintainers = with lib.maintainers; [ EpicEric ];
  };
})
