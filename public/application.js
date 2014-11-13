function scrollTo(jqElem, delay) {
  if(delay) {
    setTimeout(function() {
      scrollTo(jqElem, false);
    }, 200);
  }

  if(jqElem.length)
    jqElem[0].scrollIntoView();
}

function prepareHighlight() {
  Live.stop();

  $('#log').addClass("highlight");
  $("#log div.highlight").removeClass("highlight");
  $('#clear_selection').addClass("active");
}

function clearHighlight() {
  $('#log').removeClass("highlight");
  $("#log div.highlight").removeClass("highlight");
  $('#clear_selection').removeClass("active");
}

function afterUpdate(where) {
  where = where || $('#log');

  if($('#log').attr('data-channel').indexOf('#teamhacksung') != -1) {
    // dude
    where.find('.nick').each(function() {
      if(this.innerHTML.indexOf("nebkat") != -1) {
        var name = this.textContent, newContent = "";
        for(var i = 0; i < name.length; i++) {
          var color = "color:rgb(" + (55 + Math.floor((Math.random()*200)+1)) + "," + (55 + Math.floor((Math.random()*200)+1)) + "," + (55 + Math.floor((Math.random()*200)+1)) + ")"

          newContent += "<span style='" + color + "'>" + name[i] + "</span>";
        }
        this.innerHTML = newContent;
      }
    });
  }
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
      if(range.length == 1) {
        elem = highlightLine(range[0]);
      } else {
        elem = highlightLines(range);
      }

      if(elem.length && initial)
        scrollTo(elem);
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
  window.location.hash = '#' + newHash;
}

var Clock = {
  element: null,

  ljust: function(value) {
    if(value < 10)
      return "0" + value;
    else
      return value;
  },

  update: function() {
    var date = new Date();
    var clock = this.ljust(date.getUTCHours()) + ':' +
                this.ljust(date.getUTCMinutes()) + ' UTC';
    this.element.html(clock);

    var $this = this;
    setTimeout(function() {
      $this.update();
    }, 60 * 1000);
  },

  init: function(elem) {
    this.element = $(elem);

    var $this = this;
    setTimeout(function() {
      $this.update();
    }, (60 - new Date().getUTCSeconds()) * 1000);
  }
};

var Live = {
  eventSource: null,

  channel:     null,
  lastId:      null,

  button:      null,

  hasSupport: function() {
    return !!EventSource;
  },

  active: function() {
    return !!this.eventSource;
  },

  start: function() {
    var $this = this;
    var url = '/' + this.channel + '/stream?last_id=' + (this.lastId || "");

    this.eventSource = new EventSource(url);
    this.eventSource.onmessage = function(event) {
      var newContent = $(event.data);

      $('.log-messages').append(newContent);

      if(event.lastEventId)
        $this.lastId = event.lastEventId;

      afterUpdate(newContent);

      $this.scroll();
    };

    this.scroll();
    clearHighlight();
  },

  stop: function() {
    if(this.active())
      this.eventSource.close();

    this.eventSource = null;
  },

  scroll: function() {
    scrollTo($('.log-messages div:visible').last(), true);
  },

  toggle: function() {
    if(this.active()) {
      this.stop();
    } else {
      this.start();
    }
  },

  init: function(checkbox) {
    this.checkbox = $(checkbox);
    this.group    = this.checkbox.parent('.input-group');
    this.channel  = this.checkbox.attr('data-channel');
    this.lastId   = this.checkbox.attr('data-lastId');

    if(this.hasSupport()) {
      var $this = this;

      this.group.show();
      this.checkbox.prop('checked', true);
      this.checkbox.change(function(e) {
        $this.toggle();
      });
    }
  }
};

$(window).hashchange(function() {
  hashUpdated(false);
});

function setTheme() {
  if(docCookies.getItem('theme') == "dark") {
    $('#stylesheet').attr('href', '/style-dark.css');
  } else {
    $('#stylesheet').attr('href', '/style-light.css');
  }
}

$(document).ready(function() {
  var shift = false;

  $(document).keydown(function(e) {
    if(e.keyCode == 16) shift = true;
  });

  $(document).keyup(function(e) {
    if(e.keyCode == 16) shift = false;
  });

  $('#light_dark').click(function(event) {
    if(docCookies.getItem('theme') == "dark") {
      docCookies.setItem('theme', 'light');
    } else {
      docCookies.setItem('theme', 'dark');
    }

    setTheme();
  });

  setTheme();

  $("#clear_selection").click(function(event) {
    setHash("");

    return false;
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
    setHash(null, "");
    $("#filter").val("");

    if(highlightedElem)
      scrollTo($("#log div.highlight:first"), true);
  });

  $("#show_noise").change(function() {
    filterJoinPart();
  });

  Clock.init('#calendar .clock');

  if($('#live_logging').length)
    Live.init('#live_logging');

  var anchor = hashUpdated(true);
  afterUpdate();

  if($('#live_logging').attr('data-autostart') !== undefined &&
       anchor === undefined)
    Live.toggle();
});
