var Avrgirl = require('avrgirl-arduino');
var Promise = require('bluebird');

var board = 'nano';
var port = '/dev/ttyUSB0';
var file = '/home/ronny/pimatic-dev/node_modules/pimatic-homeduino/arduino/Homeduino_nano328.hex';


var avrgirl = new Avrgirl({
  board: board,
  port: port,
  debug: true
});
console.info('Flash normal')
avrgirl.flash(file, function (error) {
  if (error) {
    console.error(error);
  } else {
    console.info('done.');
  }

  Promise.promisifyAll(Avrgirl.prototype)

  var avrgirl = new Avrgirl({
    board: board,
    port: port,
    debug: true
  });
  console.info('Flash async')
  avrgirl.flashAsync(file).then( function (error) {
    if (error) {
      console.error(error);
    } else {
      console.info('done.');
    }
  });
});