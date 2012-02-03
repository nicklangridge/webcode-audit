$(function(){
  $('.rad').click(go);

  function go() {
    var a = $('input:radio[name=menu_1]:checked').val();
    var b = $('input:radio[name=menu_2]:checked').val();
    diff(
      $(jq(a)).val(), labelFromId(a), 
      $(jq(b)).val(), labelFromId(b)
    );
  }

  function diff(aText, aLabel, bText, bLabel) {
    var aLines = difflib.stringAsLines(aText);
    var bLines = difflib.stringAsLines(bText);
    var sm = new difflib.SequenceMatcher(aLines, bLines);
    
    $("#diff").html(diffview.buildView({ 
      baseTextLines: aLines,
      newTextLines: bLines,
      opcodes: sm.get_opcodes(),
      baseTextName: aLabel,
      newTextName: bLabel,
      viewType: 0
    }));
  }
  
  function jq(id) { 
   return '#' + id.replace(/(:|\.)/g,'\\$1');
  }
  
  function labelFromId(id) {
    var parts = id.split('_');
    var codebase = parts.shift();
    var codebase_label = $(jq(codebase + '_label')).val();
    var plugin = parts.join('_').replace(':', '/');
    plugin = plugin == '/' ? 'ensembl' : plugin; 
    return codebase_label + ' - ' + plugin;
  }
  
  go();
});

