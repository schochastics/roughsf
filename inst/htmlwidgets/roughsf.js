function drawPoly(rc, s) {
  rc.path(s.xy, {
     roughness: s.roughness,
     bowing: s.bowing,
     simplification: s.simplification,
     fill: s.fill,
     fillStyle: s.fillstyle,
     hachureGap: 4,
     fillWeight: 0.5,
     stroke: s.color,
     strokeWidth: s.width
   });
}

function drawPoint(rc, s) {
   rc.circle(Number(s.x), Number(s.y), Number(s.size), {
     roughness: s.roughness,
     bowing: s.bowing,
     fill: s.fill,
     fillStyle: s.fillstyle,
     hachureGap: 4,
     fillWeight: 0.5,
     stroke: s.color,
     strokeWidth: s.width
   });
}

function drawLine(rc, s) {
  rc.path(s.xy, {
     roughness: s.roughness,
     bowing: s.bowing,
     stroke: s.color,
     strokeWidth: s.width
   });
}

function drawText(rc,ctx,s) {
  ctx.fillStyle = s.color;
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillText(s.label,Number(s.x), Number(s.y));
}

HTMLWidgets.widget({

  name: 'roughsf',

  type: 'output',

  factory: function(el, width, height) {

    return {
      renderValue: function(x) {

        // Create Canvas element in DOM
        var canvas = document.createElement("canvas");
        canvas.setAttribute("id", x.id);
        canvas.setAttribute("width", width);
        canvas.setAttribute("height", height);
        el.appendChild(canvas);

        // Insert rough canvas in the new canvas element
        const rc = rough.canvas(document.getElementById(x.id));

        // Create context for text shape
        const c = document.getElementById(x.id);
        var ctx = c.getContext("2d");
        ctx.font = x.font;

        x.data.map(function(s) {
          if(s.shape === "POLYGON"){
            drawPoly(rc, s);
          }
          if(s.shape === "LINESTRING"){
            drawLine(rc, s);
          }

          if(s.shape === "POINT"){
            drawPoint(rc,s);
          }

          if(s.shape === "TEXT"){
            drawText(rc,ctx,s);
          }

          if(s.shape === "TITLE"){
            ctx.font = x.title_font;
            drawText(rc,ctx,s);
            ctx.font = x.font;
          }

        });
      },
      resize: function(width, height) {
        // TODO
      }
    };
  }
});
