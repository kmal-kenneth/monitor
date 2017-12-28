public class Application : Gtk.Application {

    public Application () {
        Object (application_id: "com.github.yourusername.yourrepositoryname",
        flags: ApplicationFlags.FLAGS_NONE);
    }

    protected override void activate () {
        var app_window = new Gtk.ApplicationWindow (this);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.row_spacing = 6;

        var title_label = new Gtk.Label (_("Notifications"));
        var show_button = new Gtk.Button.with_label (_("Show"));
        
        show_button.clicked.connect (() => {
            var notification = new Notification (_("Hello World"));
            var icon = new GLib.ThemedIcon ("dialog-warning");
            notification.set_icon (icon);
            notification.set_body (_("This is my first notification!"));
            this.send_notification ("notify.app", notification);
        });
        
        var replace_button = new Gtk.Button.with_label (_("Replace"));
        replace_button.clicked.connect (() => {
            var notification = new Notification (_("Hello Again"));
            notification.set_body (_("This is my second Notification!"));

            var icon = new GLib.ThemedIcon ("dialog-warning");
            notification.set_icon (icon);
            
            notification.set_priority (NotificationPriority.URGENT);
            

            this.send_notification ("com.github.yourusername.yourrepositoryname", notification);
        });
        
        grid.add (title_label);
        grid.add (show_button);
        grid.add (replace_button);

        app_window.add (grid);
        app_window.show_all ();

        app_window.show ();
    }

    public static int main (string[] args) {
        var app = new Application ();
        return app.run (args);
    }
}
