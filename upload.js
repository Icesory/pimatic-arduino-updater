var Avrgirl = require('avrgirl-arduino');

var avrgirl = new Avrgirl({
  board: 'nano',
  port: '/dev/ttyUSB0',
  debug: true
});

avrgirl.flash('/home/ronny/pimatic-dev/node_modules/pimatic-homeduino/arduino/Homeduino_nano328.hex', function (error) {
  if (error) {
    console.error(error);
  } else {
    console.info('done.');
  }
});