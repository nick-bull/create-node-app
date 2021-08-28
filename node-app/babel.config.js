import packageConfig from './package.json';

/** 
 * Converts the "imports" entry of the root-level ./package.json to aliases
 * for use in the `babel-plugin-module-resolver` babel plugin
 */
const fetchPackageImportsAsAliasMap = () => {
  const imports = packageConfig.imports;
  const importEntries = Object.entries(imports);

  const removeTrailingExpansion = (item) => item.replace(/\/\*$/, '');
  const moduleToCommonjsDir = (item) => item.replace(/^\.\/src/, './lib');
  const importAliasTransformer = ([key, val]) => [
  removeTrailingExpansion(moduleToCommonjsDir(key)),
  removeTrailingExpansion(val),
  ];

  const aliasImportEntries = importEntries.map(importAliasTransformer);
  return Object.fromEntries(aliasImportEntries);
};

const aliasImports = fetchPackageImportsAsAliasMap();

export default {
  'presets': [
    ['@babel/preset-env', {targets: {node: 'current'}}],
  ],
  'plugins': [
    ['@babel/plugin-transform-runtime', {'regenerator': true}],
    ['module-resolver', {'alias': aliasImports}],
  ],
};
