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
      "^.+\\.[t|j]sx?$": "babel-jest",
    },
};