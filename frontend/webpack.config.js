const webpack = require('webpack');
const path = require('path');

module.exports = {
    entry: './bin/app.js',
    output: {
        path: path.join(__dirname, '..', 'static', 'js'),
        filename: 'bundle.js'
    },

    plugins: [
        new webpack.optimize.UglifyJsPlugin({
            compress: {
                warnings: false,
            },
            output: {
                comments: false,
            },
        }),
    ],

    resolve: {
      alias: {
        'react': 'preact-compat',
        'react-dom': 'preact-compat'
      },
      modules: [
        'node_modules',
        'bower_components'
      ],
      extensions: ['.js', '.purs']
    }
};
