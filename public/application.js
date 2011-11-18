function prepareHighlight() {
  $('#log').addClass("highlight");
  $("#log div.highlight").removeClass("highlight");
  $('#clear_selection').addClass("active");
}

function clearHighlight() {
  $('#log').removeClass("highlight");
  $("#log div.highlight").removeClass("highlight");
  $('#clear_selection').removeClass("active");
}

function highlightLines(range) {
  prepareHighlight();

  range = range.sort();

  var first = range[0];
  var last  = range[1] || range[0];

  $("#log .timestamp").each(function() {
    var $entry = $(this).parent();

    if (this.id >= first && this.id <= last)
      $entry.addClass("highlight");
    else
      $entry.removeClass("highlight");
  })
}

function highlightChain(id) {
  prepareHighlight();

  while(true) {
    var elems = $("#log [data-group='" + id + "']");
    elems.addClass("highlight");

    var attr = elems[0].attributes.getNamedItem('data-previous_group');
    if(!attr) return elems[0];
    id = attr.value;
  }
}

function filterLines(query) {
  if(query == null || query == "") {
    $("#clear_filter").hide();
    $("#log div").show();
  } else {
    $("#clear_filter").show();

    query = query.toLowerCase();
    $("#log div").each(function() {
      if(this.textContent.toLowerCase().indexOf(query) != -1) {
        $(this).show();
      } else {
        $(this).hide();
      }
    });
  }
}

function update(initial) {
  var current = window.location.hash.substring(1).split(";");
  var selection = current[0], filter = current[1];

  if(selection != null) {
    if(selection == "") {
      clearHighlight();
    } else {
      prepareHighlight();

      var anchors = selection.split("-");
      if(anchors[1] == 'chain') {
        var elem = highlightChain($("[id='" + anchors[0] + "']:last").parent()[0].attributes.getNamedItem('data-group').value);
      } else {
        if(anchors && anchors.length > 0)
          var elem = $("#" + anchors[0])[0];
        highlightLines(anchors);
      }

      if(elem && initial)
        elem.scrollIntoView();
    }
  }

  if(initial)
    $('#filter').val(filter);

  filterLines(filter);

  if(anchors)
    return anchors[0];
}

function setHash(selection, filter) {
  var current = window.location.hash.substring(1).split(";");
  var currentSelection = current[0], currentFilter = current[1];

  if(selection != null) currentSelection = selection;
  if(filter != null)    currentFilter = filter;

  var newHash = (currentSelection || '') + ';' + (currentFilter || '');

  var elems = $("[id='" + newHash + "']");
  elems.attr('id', ''); 
  window.location.hash = '#' + newHash;
  elems.attr('id', currentSelection);
}

$(window).hashchange(function() {
  update();
});

$(document).ready(function() {
  update(true);

  var shift = false;

  $("a.timestamp").click(function() {
    prepareHighlight();

    if(shift) {
      var from = update();
      var to = this.id;

      setHash(from + "-" + to);
    } else {
      setHash(this.id);
    }

    return false;
  });

  $(document).keydown(function(e) {
    if(e.keyCode == 16) shift = true;
  });

  $(document).keyup(function(e) {
    if(e.keyCode == 16) shift = false;
  });

  $("#clear_selection").click(function() {
    setHash("");
    clearHighlight();

    return false;
  });

  var filterTimeout = null;
  $("#filter").keyup(function() {
    var $this = this;

    clearTimeout(filterTimeout);
    filterTimeout = setTimeout(function() {
      setHash(null, $this.value);
    }, 500);
  });

  $("#clear_filter").click(function() {
    var highlightedElem = $("#log div.highlight:first")[0];

    setHash(null, "");
    $("#filter").val("");

    if(highlightedElem) {
      setTimeout(function() {
        highlightedElem.scrollIntoView();
      }, 200);
    }
  });

  $(".chain").click(function() {
     setHash($(this).parent().find('.timestamp')[0].id + "-chain");
  });
});
