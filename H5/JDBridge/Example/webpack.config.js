const HtmlWebpackPlugin = require('html-webpack-plugin');
const { resolve } = require('path');
 
module.exports = {
  entry: './src/index.js',
  output: {
    path: resolve(__dirname, './dist'),
    filename: 'bundle.js',
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: './src/jdbridge_demo.html',
      filename: 'jdbridge_demo.html'
    })
  ],
  mode: 'development'
};