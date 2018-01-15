// (C) sbrin - https://github.com/sbrin
// https://gist.github.com/sbrin/6801034
window.word_filter = function(editor){
    var content = editor.html();

    // Word comments like conditional comments etc
    content = content.replace(/<!--[\s\S]+?-->/gi, '');

    // Remove comments, scripts (e.g., msoShowComment), XML tag, VML content,
    // MS Office namespaced tags, and a few other tags
    content = content.replace(/<(!|script[^>]*>.*?<\/script(?=[>\s])|\/?(\?xml(:\w+)?|img|meta|link|style|\w:\w+)(?=[\s\/>]))[^>]*>/gi, '');

    // Convert <s> into <strike> for line-though
    content = content.replace(/<(\/?)s>/gi, "<$1strike>");

    // Replace nbsp entites to char since it's easier to handle
    //content = content.replace(/&nbsp;/gi, "\u00a0");
    content = content.replace(/&nbsp;/gi, ' ');

    // Convert <span style="mso-spacerun:yes">___</span> to string of alternating
    // breaking/non-breaking spaces of same length
    content = content.replace(/<span\s+style\s*=\s*"\s*mso-spacerun\s*:\s*yes\s*;?\s*"\s*>([\s\u00a0]*)<\/span>/gi, function(str, spaces) {
        return (spaces.length > 0) ? spaces.replace(/./, " ").slice(Math.floor(spaces.length/2)).split("").join("\u00a0") : '';
    });

    editor.html(content);

    // Parse out list indent level for lists
    $('p', editor).each(function(){
        var str = $(this).attr('style');
        var matches = /mso-list:\w+ \w+([0-9]+)/.exec(str);
        if (matches) {
            $(this).data('_listLevel',  parseInt(matches[1], 10));
        }
    });

    // Parse Lists
    var last_level=0;
    var pnt = null;
    $('p', editor).each(function(){
        var cur_level = $(this).data('_listLevel');
        if(cur_level != undefined){
            var txt = $(this).text();
            var list_tag = '<ul></ul>';
            if (/^\s*\w+\./.test(txt)) {
                var matches = /([0-9])\./.exec(txt);
                if (matches) {
                    var start = parseInt(matches[1], 10);
                    list_tag = start>1 ? '<ol start="' + start + '"></ol>' : '<ol></ol>';
                }else{
                    list_tag = '<ol></ol>';
                }
            }

            if(cur_level>last_level){
                if(last_level==0){
                    $(this).before(list_tag);
                    pnt = $(this).prev();
                }else{
                    pnt = $(list_tag).appendTo(pnt);
                }
            }
            if(cur_level<last_level){
                for(var i=0; i<last_level-cur_level; i++){
                    pnt = pnt.parent();
                }
            }
            $('span:first', this).remove();
            pnt.append('<li>' + $(this).html() + '</li>')
            $(this).remove();
            last_level = cur_level;
        }else{
            last_level = 0;
        }
    })

    // style and align is handled by utils.coffee it self, don't clean it here
    //$('[style]', editor).removeAttr('style');
    //$('[align]', editor).removeAttr('align');
    $('span', editor).replaceWith(function() {return $(this).contents();});
    $('span:empty', editor).remove();
    $("[class^='Mso']", editor).removeAttr('class');
    $('p:empty', editor).remove();
    return editor
}
