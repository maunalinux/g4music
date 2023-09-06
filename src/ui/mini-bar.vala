namespace G4 {

    public class MiniBar : Adw.ActionRow {
        private Gtk.Image _cover = new Gtk.Image ();
        private Gtk.Label _title = new Gtk.Label (null);
        private Gtk.Label _time = new Gtk.Label ("0:00");
        private Gtk.Button _prev = new Gtk.Button ();
        private Gtk.Button _play = new Gtk.Button ();
        private Gtk.Button _next = new Gtk.Button ();
        private int _duration = 0;
        private int _position = 0;

        private CrossFadePaintable _paintable = new CrossFadePaintable ();
        private Adw.Animation? _fade_animation = null;

        construct {
            halign = Gtk.Align.FILL;
            hexpand = true;
            height_request = 60;

            var controller = new Gtk.GestureClick ();
            controller.released.connect (this.activate);
            add_controller (controller);
            activatable_widget = this;

            var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            vbox.halign = Gtk.Align.START;
            vbox.hexpand = true;
            vbox.valign = Gtk.Align.CENTER;
            vbox.append (_title);
            vbox.append (_time);
            add_prefix (vbox);
            add_prefix (_cover);

            _cover.valign = Gtk.Align.CENTER;
            _cover.margin_start = 2;
            _cover.margin_end = 6;
            _cover.pixel_size = 40;
            _cover.paintable = new RoundPaintable (_paintable);
            _paintable.queue_draw.connect (_cover.queue_draw);

            _title.halign = Gtk.Align.START;
            _title.ellipsize = Pango.EllipsizeMode.END;
            _title.add_css_class ("title-leading");

            _time.halign = Gtk.Align.START;
            _time.add_css_class ("dim-label");
            _time.add_css_class ("numeric");

            var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
            hbox.valign = Gtk.Align.CENTER;
            add_suffix (hbox);

            _prev.valign = Gtk.Align.CENTER;
            _prev.action_name = ACTION_APP + ACTION_PREV;
            _prev.icon_name = "media-skip-backward-symbolic";
            _prev.tooltip_text = _("Play Previous");
            _prev.add_css_class ("circular");
            _prev.add_css_class ("flat");
            hbox.append (_prev);

            _play.valign = Gtk.Align.CENTER;
            _play.action_name = ACTION_APP + ACTION_PLAY_PAUSE;
            _play.icon_name = "media-playback-start-symbolic";
            _play.tooltip_text = _("Play/Pause");
            _play.add_css_class ("circular");
            _play.add_css_class ("flat");
            hbox.append (_play);

            _next.valign = Gtk.Align.CENTER;
            _next.action_name = ACTION_APP + ACTION_NEXT;
            _next.icon_name = "media-skip-forward-symbolic";
            _next.tooltip_text = _("Play Next");
            _next.add_css_class ("circular");
            _next.add_css_class ("flat");
            hbox.append (_next);

            var app = (Application) GLib.Application.get_default ();
            var player = app.player;
            player.duration_changed.connect (on_duration_changed);
            player.position_updated.connect (on_position_changed);
            player.state_changed.connect (on_state_changed);
        }

        public Gdk.Paintable? cover {
            get {
                return _paintable.paintable;
            }
            set {
                _paintable.paintable = value;
                var target = new Adw.CallbackAnimationTarget ((value) => _paintable.fade = value);
                _fade_animation?.pause ();
                _fade_animation = new Adw.TimedAnimation (_cover, 1 - _paintable.fade, 0, 800, target);
                ((!)_fade_animation).done.connect (() => {
                    _paintable.previous = null;
                    _fade_animation = null;
                });
                _fade_animation?.play ();
            }
        }

        public new string title {
            set {
                _title.label = value;
            }
        }

        public void size_to_change (int panel_width) {
            _prev.visible = panel_width >= 360;
        }

        public override void snapshot (Gtk.Snapshot snapshot) {
            base.snapshot (snapshot);
#if GTK_4_10
            var color = get_color ();
#else
            var color = get_style_context ().get_color ();
#endif
            color.alpha = 0.25f;
            var line_width = scale_factor >= 2 ? 0.5f : 1;
            var rect = Graphene.Rect ();
            rect.init (0, 0, get_width (), line_width);
            snapshot.append_color (color, rect);
        }

        private void on_duration_changed (Gst.ClockTime duration) {
            var value = GstPlayer.to_second (duration);
            if (_duration != (int) value) {
                _duration = (int) value;
                update_time_label ();
            }
        }

        private void on_position_changed (Gst.ClockTime position) {
            var value = GstPlayer.to_second (position);
            if (_position != (int) value) {
                _position = (int) value;
                update_time_label ();
            }
        }

        private void on_state_changed (Gst.State state) {
            var playing = state == Gst.State.PLAYING;
            _play.icon_name = playing ? "media-playback-pause-symbolic" : "media-playback-start-symbolic";
        }

        private void update_time_label () {
            if (_duration > 0)
                _time.label = format_time (_position) + "/" + format_time (_duration);
            else
                _time.label = "";
        }
    }
}
