const transformImportMetaHot = () => ({
    visitor: {
      MemberExpression(path) {
        const { node } = path;
        if (
          node.object?.type === "MetaProperty" &&
          node.object.meta?.name === "import" &&
          node.object.property?.name === "meta" &&
          node.property?.type === "Identifier" &&
          node.property.name === "hot"
        ) {
          path.replaceWith(path.scope.buildUndefinedNode());
        }
      },
    },
});

export default {
    testEnvironment: "jest-environment-jsdom", // Same name of the lib you installed
    setupFilesAfterEnv: ["<rootDir>/jest.setup.js"], // The file you created to extend jest config and "implement" the jest-dom environment in the jest globals
    moduleNameMapper: {
      "\\.svg\\?react$": "<rootDir>/test/__mocks__/fileMock.js", 
      "\\.(svg|png|jpg|jpeg|gif|ttf|eot)$": "<rootDir>/test/__mocks__/fileMock.js", // The global stub for weird files
      "\\.(css|less|scss)$": "identity-obj-proxy", // The mock for style related files
      "^@/(.*)$": "<rootDir>/src/$1", // [optional] Are you using aliases?
    },
    transform: {
      "^.+\\.[cm]?[tj]sx?$": [
        "babel-jest",
        {
          babelrc: false,
          configFile: false,
          presets: [
            ["@babel/preset-env", { targets: { node: "current" }, modules: "commonjs" }],
            ["@babel/preset-react", { runtime: "automatic" }],
          ],
          plugins: ["babel-plugin-transform-vite-meta-env", transformImportMetaHot],
        },
      ],
    },
    transformIgnorePatterns: [
      "[/\\\\]node_modules[/\\\\](?!.*(react-router|react-router-dom|cookie-es))",
    ],
};
