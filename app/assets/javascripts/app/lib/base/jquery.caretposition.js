/**
 * jQuery plugin for getting position of cursor in textarea

 * @license under GNU license
 * @author Bevis Zhao (i@bevis.me, http://bevis.me)
 */
$(function() {

	var calculator = {
		// key styles
		primaryStyles: ['fontFamily', 'fontSize', 'fontWeight', 'fontVariant', 'fontStyle',
			'paddingLeft', 'paddingTop', 'paddingBottom', 'paddingRight',
			'marginLeft', 'marginTop', 'marginBottom', 'marginRight',
			'borderLeftColor', 'borderTopColor', 'borderBottomColor', 'borderRightColor',
			'borderLeftStyle', 'borderTopStyle', 'borderBottomStyle', 'borderRightStyle',
			'borderLeftWidth', 'borderTopWidth', 'borderBottomWidth', 'borderRightWidth',
			'line-height', 'outline'],

		specificStyle: {
			'word-wrap': 'break-word',
			'overflow-x': 'hidden',
			'overflow-y': 'auto'
		},

		simulator : $('<div id="textarea_simulator"/>').css({
				position: 'absolute',
				top: 0,
				left: 0,
				visibility: 'hidden'
			}).appendTo(document.body),

		toHtml : function(text) {
			return text.replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/\n/g, '<br>')
				.split(' ').join('<span style="white-space:prev-wrap">&nbsp;</span>');
		},
		// calculate position
		getCaretPosition: function() {
			var cal = calculator, self = this, element = self[0], elementOffset = self.offset();

			// IE has easy way to get caret offset position
			if ($.browser.msie && $.browser.version <= 9) {
				// must get focus first
				element.focus();
			    var range = document.selection.createRange();
			    $('#hskeywords').val(element.scrollTop);
			    return {
			        left: range.boundingLeft - elementOffset.left,
			        top: parseInt(range.boundingTop) - elementOffset.top + element.scrollTop
						+ document.documentElement.scrollTop + parseInt(self.getComputedStyle("fontSize"))
			    };
			}

			cal.simulator.empty();
			// clone primary styles to imitate textarea
			$.each(cal.primaryStyles, function(index, styleName) {
				self.cloneStyle(cal.simulator, styleName);
			});

			// caculate width and height
			cal.simulator.css($.extend({
				'width': self.width(),
				'height': self.height()
			}, cal.specificStyle));

			var value = (self.val() || self.text()), cursorPosition = self.getCursorPosition();
			var beforeText = value.substring(0, cursorPosition),
				afterText = value.substring(cursorPosition);

			var before = $('<span class="before"/>').html(cal.toHtml(beforeText)),
				focus = $('<span class="focus"/>'),
				after = $('<span class="after"/>').html(cal.toHtml(afterText));

			cal.simulator.append(before).append(focus).append(after);
			var focusOffset = focus.offset(), simulatorOffset = cal.simulator.offset();
			// alert(focusOffset.left  + ',' +  simulatorOffset.left + ',' + element.scrollLeft);
			return {
				top: focusOffset.top - simulatorOffset.top - element.scrollTop
					// calculate and add the font height except Firefox
					+ ($.browser.mozilla ? 0 : parseInt(self.getComputedStyle("fontSize"))),
				left: focus[0].offsetLeft -  cal.simulator[0].offsetLeft - element.scrollLeft
			};
		}
	};

	$.fn.extend({
		setCursorPosition : function(position){
	    if(this.length == 0) return this;
	    return $(this).setSelection(position, position);
		},
		setSelection: function(selectionStart, selectionEnd) {
	    if(this.length == 0) return this;
	    input = this[0];

	    if (input.createTextRange) {
	        var range = input.createTextRange();
	        range.collapse(true);
	        range.moveEnd('character', selectionEnd);
	        range.moveStart('character', selectionStart);
	        range.select();
	    } else if (input.setSelectionRange) {
	        input.focus();
	        input.setSelectionRange(selectionStart, selectionEnd);
	    } else {
	    	var el = this.get(0);

				var range = document.createRange();
				range.collapse(true);
				range.setStart(el.childNodes[0], selectionStart);
				range.setEnd(el.childNodes[0], selectionEnd);

				var sel = window.getSelection();
				sel.removeAllRanges();
				sel.addRange(range);
	    }

	    return this;
		},
		getComputedStyle: function(styleName) {
			if (this.length == 0) return;
			var thiz = this[0];
			var result = this.css(styleName);
			result = result || ($.browser.msie ?
				thiz.currentStyle[styleName]:
				document.defaultView.getComputedStyle(thiz, null)[styleName]);
			return result;
		},
		// easy clone method
		cloneStyle: function(target, styleName) {
			var styleVal = this.getComputedStyle(styleName);
			if (!!styleVal) {
				$(target).css(styleName, styleVal);
			}
		},
		cloneAllStyle: function(target, style) {
			var thiz = this[0];
			for (var styleName in thiz.style) {
				var val = thiz.style[styleName];
				typeof val == 'string' || typeof val == 'number'
					? this.cloneStyle(target, styleName)
					: NaN;
			}
		},
		getCursorPosition : function() {
			var element = input = this[0];
			var value = (input.value || input.innerText)

		    if(!this.data("lastCursorPosition")){
		    	this.data("lastCursorPosition",0);
		    }

		    var lastCursorPosition = this.data("lastCursorPosition");

		  if (document.selection) {
		     input.focus();
		      var sel = document.selection.createRange();
		      var selLen = document.selection.createRange().text.length;
		      sel.moveStart('character', -value.length);
		      lastCursorPosition = sel.text.length - selLen;
		  } else if (input.selectionStart || input.selectionStart == '0') {
		  	return input.selectionStart;
		  } else if (typeof window.getSelection != "undefined" && window.getSelection().rangeCount>0) {
		  	  try{
		  	  var selection = window.getSelection();
		      var range = selection.getRangeAt(0);
		      var preCaretRange = range.cloneRange();
		      preCaretRange.selectNodeContents(element);
		      preCaretRange.setEnd(range.endContainer, range.endOffset);
		      lastCursorPosition =  preCaretRange.toString().length;
		  	}catch(e){
		  		lastCursorPosition = this.data("lastCursorPosition");	
		  	}
		  } else if (typeof document.selection != "undefined" && document.selection.type != "Control") {
		      var textRange = document.selection.createRange();
		      var preCaretTextRange = document.body.createTextRange();
		      preCaretTextRange.moveToElementText(element);
		      preCaretTextRange.setEndPoint("EndToEnd", textRange);
		      lastCursorPosition =  preCaretTextRange.text.length;
		  }

    		this.data("lastCursorPosition",lastCursorPosition);
		  return lastCursorPosition;
	  },
		getCaretPosition: calculator.getCaretPosition
	});
});
