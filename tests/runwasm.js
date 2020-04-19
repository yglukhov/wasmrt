process.on('unhandledRejection', error => {
  // Will print "unhandledRejection err is not defined"
  console.log('Unhandled promise rejection', error);
  process.exit(1)
});

function runNimWasm(w){for(i of WebAssembly.Module.exports(w)){n=i.name;if(n[0]==';'){new Function('m',n)(w);break}}}

WebAssembly.compile(require("fs").readFileSync(process.argv[2])).then(runNimWasm)
