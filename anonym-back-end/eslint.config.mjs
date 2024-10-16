import globals from "globals";
import pluginJs from "@eslint/js";

export default [
  {
    files: ["**/*.js"], 
    languageOptions: {
      sourceType: "commonjs",
      globals: {
        ...globals.browser,
        ...globals.jest,  
        __dirname: "readonly", 
        __filename: "readonly", 
        process: "readonly",
      },
    },
  },
  pluginJs.configs.recommended,
];