#!/bin/sh
':' //; exec "$(command -v nodejs || command -v node)" "$0" "$@"

const path = require('path');
const fs   = require('fs');
const ENV  = process.env;


let CONFIG_SOURCE = resolvePath(process.argv[2])
,   CONFIG_DESTINATION = resolvePath(process.argv[3])
,   config
,   segments;

if (!CONFIG_DESTINATION) {
    return exit('Invalid argument. Provide resolved config file system location as second possitional parameter.');
}

try {
    config = fs.readFileSync(CONFIG_SOURCE).toString();
} catch(e) {
    if (e.code === 'ENOENT') {
        return exit('Unknown config.json5 service configuration destination. ' + e.message);
    }
}

segments = getSegments(config);
config   = replaceSegments(config, segments);

function exit(message) {
    console.error(message);
    console.log('\nUSAGE:');
    console.log(
        'resolve-service-conf.sh <config-template-source-path> <resolved-config-destionation>'
    );
    process.exit(1);
}

/**
 * @param {String} srouce
 * @return {Array}
 */
function getSegments(source) {

    let regex = /\$\{([0-9a-zA-Z-_]+)(:-.+){0,1}\}/g;
    let matches, segments = [];
    while (matches = regex.exec(source)) {
        if (matches[0]) {
            let segment = {
                name: matches[1]
            };

            if (matches[2]) {
                let subSource = matches[2];
                let subSegments = getSegments(subSource);

                segment.unresolvedDefault = subSource;

                subSource = replaceSegments(subSource, subSegments);
                segment.default = subSource;
            }

            segments.push(segment);
        }
    }

    return segments;
}

function replaceSegments(source, segments) {
    segments.forEach(function(segment) {
        let value = ENV[segment.name];

        if (!ENV.hasOwnProperty(segment.name)) {
            if (!segment.hasOwnProperty('default')) {
                return;
            }

            value = segment.default.slice(2);
        }

        let r = `\\$\\{${segment.name}`;
        if (segment.unresolvedDefault) {
            r += `(${escapeRegExp(segment.unresolvedDefault)}){0,1}`;
        }
        r += `\\}`;

        let regex = new RegExp(r, 'g');
        source = source.replace(regex, value);

    });

    return source;
}

function escapeRegExp(str) {
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
}

function resolvePath(p) {
    if (!p) {
        return p;
    }

    if (typeof p === 'string' && p[0] === path.sep) {
        return p;
    }

    return path.resolve(process.cwd() + '/' + p)
}

let destionationDir = path.dirname(CONFIG_DESTINATION);

if (!fs.existsSync(destionationDir)) {
    fs.mkdirSync(destionationDir);
}

fs.writeFileSync(CONFIG_DESTINATION, config);
