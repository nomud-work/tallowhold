const p = require('puppeteer-core');
const fs = require('fs');
(async () => {
  const size = parseInt(process.argv[2] || '560');
  const b = await p.launch({executablePath: process.env.CHROME_PATH || '/usr/bin/google-chrome', headless:'new', args:['--no-sandbox']});
  const pg = await b.newPage(); const h = Math.round(size*1.4);
  await pg.setViewport({width:size, height:h});
  fs.mkdirSync(__dirname + '/png', {recursive:true});
  for (const f of fs.readdirSync(__dirname + '/svg').filter(f => f.endsWith('.svg'))) {
    const s = fs.readFileSync(__dirname + '/svg/' + f, 'utf8');
    await pg.setContent(`<html><body style="margin:0;background:transparent"><div style="width:${size}px;height:${h}px">${s.replace(/width="\d+" height="\d+"/,'').replace('<svg ', `<svg width="100%" height="100%" `)}</div></body></html>`);
    await pg.screenshot({path: __dirname + '/png/' + f.replace('.svg','.png'), omitBackground:true, clip:{x:0,y:0,width:size,height:h}});
  }
  await b.close(); console.log('done', fs.readdirSync(__dirname+'/png').length);
})();
