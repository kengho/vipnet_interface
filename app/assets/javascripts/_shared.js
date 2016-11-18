vipnetInterface = {
  nodes: {},
  params: {},

  snackbarContainer: function() {
    return $("#snackbar")[0];
  },

  showSnackbar: function(message, timeout = 3000) {
    var snackbarContainer = vipnetInterface.snackbarContainer();
    var msgToShow = I18n["snackbar"][message] || message;

    var data = { message: msgToShow }
    if(timeout == -1) {
      data.timeout = 99999999;
      data.actionHandler = vipnetInterface.hideSnackbar;
      data.actionText = I18n["snackbar"]["close"];
    } else {
      data.timeout = timeout;
    }

    snackbarContainer.MaterialSnackbar.showSnackbar(data);
  },

  hideSnackbar: function() {
    var snackbarContainer = vipnetInterface.snackbarContainer();
    snackbarContainer.MaterialSnackbar.cleanup_();
  },

  // http://stackoverflow.com/a/3169849
  clearSelection: function() {
    if(window.getSelection) {
      if(window.getSelection().empty) {
        window.getSelection().empty();
      } else if(window.getSelection().removeAllRanges) {
        window.getSelection().removeAllRanges();
      }
    } else if(document.selection) {
      document.selection.empty();
    }
  },

  bindEventRadio: function() {
    $("div[data-user-settings] input[type='radio']").change(function() {
      var userUrl = $(this).parent().data("user-url");
      var name = $(this).attr("name");
      var value = $(this).attr("value");

      $.ajax({
        url: userUrl,
        method: "patch",
        dataType: "script",
        data: {
          utf8: true,
          name: name,
          value: value,
        },
        success: function() {
          if (name == "nodes_per_page") {
            vipnetInterface.nodes.ajax.load(vipnetInterface.params);
          } else if(name == "locale") {
            location.reload();
          }
        },
      });
    });
  },

  bindHome: function() {
    $("*[data-load='home']").click(function() {
      $("#progress").vipnetInterface().tmpShow();
      vipnetInterface.nodes.ajax.load();
    });
  },

  bindSelectRow: function() {
    $("*[data-selectable]").click(function(e) {
      var vid = $(this).data("vid");

      if(e.shiftKey) {
        vipnetInterface.nodes.export.shiftSelectRow(vid);
      } else {
        // http://stackoverflow.com/a/10390097/6376451
        // e.button == 1 for middle button
        // prevent triggering by middle button or text select
        var selection = getSelection().toString();
        if(!selection && e.button != 1) {
          vipnetInterface.nodes.export.toggleSelectRow(vid);
        }
      }
    });
  },

  selectWhatWasSelected: function() {
    $("*[data-selectable]").each(function(_, row) {
      var vid = $(row).data("vid");
      var data = vipnetInterface.nodes.export.data[vid];
      if(data && data.selected) {
        vipnetInterface.nodes.export.selectRow(vid);
      }
    });
  },

  stopPropagation: function() {
    $("*[data-stop-propagation]").click(function(e) {
      e.stopPropagation();
    });
  },
};

$(document).ready(function() {
  // radios in header and profile
  vipnetInterface.bindEventRadio();
  vipnetInterface.bindHome();
});