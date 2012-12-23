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

function highlightLine(id) {
  $(".log-messages > div").removeClass("highlight");

  if((by_id = $("#" + id)).length) {
    return by_id.addClass("highlight");
  } else {
    return $("[data-timestamp=" + id + "]").addClass('highlight');
  }
}

function highlightLines(range) {
  range = range.map(function(e) { return parseInt(e, 10); }).sort();

  var first = range[0],
      last  = range[1],
      elem;

  $(".log-messages > div").each(function() {
    var timestamp = parseInt($(this).attr('data-timestamp'), 10);

    if (timestamp >= first && timestamp <= last) {
      if(!elem)
        elem = $(this);

      $(this).addClass("highlight");
    }
  })

  return elem;
}

function highlightChain(group) {
  while(true) {
    var elems = $("#log [data-group='" + group + "']");
    elems.addClass("highlight");

    group = elems.attr('data-previous_group');
    if(!group) return elems;
  }
}

function filterJoinPart() {
  if($('#show_noise').is(':checked')) {
    $("#log").removeClass('without-noise');
  } else {
    $("#log").addClass('without-noise');
  }
}

function filterLines(query) {
  if(query == null || query == "") {
    $("#clear_filter").hide();
    $("#log div").show();
  } else {
    $("#clear_filter").show();

    query = query.toLowerCase();
    $(".log-messages > div").each(function() {
      if(this.textContent.toLowerCase().indexOf(query) != -1) {
        $(this).show();
      } else {
        $(this).hide();
      }
    });
  }
}

function hashUpdated(initial) {
  var current   = window.location.hash.substring(1).split(";");
  var selection = current[0], filter = current[1];
  var elem;

  if(selection != null) {
    if(selection == "") {
      clearHighlight();
    } else {
      prepareHighlight();

      var range = selection.split("-");
      if(range[1] == 'chain') {
        elem = highlightChain($("#" + range[0]).attr('data-group'));
      } else if(range.length == 1) {
        elem = highlightLine(range[0]);
      } else {
        elem = highlightLines(range);
      }

      if(elem[0] && initial)
        elem[0].scrollIntoView();
    }
  }

  if(initial)
    $('#filter').val(filter);

  filterLines(filter);

  if(range)
    return range[0];
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

$(window).hashchange(hashUpdated);

$(document).ready(function() {
  hashUpdated(true);

  var shift = false;

  $(document).keydown(function(e) {
    if(e.keyCode == 16) shift = true;
  });

  $(document).keyup(function(e) {
    if(e.keyCode == 16) shift = false;
  });

  $("#log .log-messages, #clear_selection").click(function(event) {
    if($(event.target).is($(this))) {
      setHash("");

      return false;
    }
  });

  $("a.timestamp").click(function() {
    var $line = $(this).parent();

    if(shift) {
      var from = hashUpdated(), elem;

      if((from_timestamp = $("#" + from).attr('data-timestamp')))
        from = from_timestamp;

      var to = $line.attr('data-timestamp');

      setHash(from + "-" + to);
    } else {
      setHash($line.attr('id'));
    }

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

  $("#show_noise").change(function() {
    filterJoinPart();
  });

  $(".chain").click(function() {
     setHash($(this).parents('.talk').attr('id') + "-chain");

     return false;
  });
});
