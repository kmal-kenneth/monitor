/*
* Copyright (c) 2017-2017 kaml-kenneth (https://github.com/kmal-kenneth)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Kenet Mauricio Acuña Lago <kmal.kenneth@live.com>
*/

namespace monitor {

    public class MainWindow : Gtk.ApplicationWindow {
        // application reference
        private Application app;

        // Widgets
        private Gtk.HeaderBar header;
        private Gtk.Paned layout;
        private Sidebar sidebar;

        private Search search;
        private Gtk.Button kill_process_button;
        private Gtk.ScrolledWindow process_view_window;
        private ProcessView process_view;

        private ProcessMonitor process_monitor;
        private ApplicationProcessModel app_model;
        private Gtk.TreeModelSort sort_model;

        public Gtk.TreeModelFilter filter;

        public MainWindow (Application app) {
            this.app = app;
            this.set_application (this.app);
            this.set_default_size (880, 720);
            this.window_position = Gtk.WindowPosition.CENTER;
            this.get_style_context ().add_class ("rounded");

            setup_ui ();
        }

         private void setup_ui () {
            // setup header bar
            header = new Gtk.HeaderBar ();
            header.show_close_button = true;
            //header.get_style_context ().add_class ("default-decoration");
            header.title = _("Monitor");
            header.subtitle = _("A litle system monitor");

            kill_process_button = new Gtk.Button.with_label (_("End process"));
            kill_process_button.clicked.connect (kill_process);

            // put the buttons in the headerbar
            header.pack_start (kill_process_button);

            // TODO: Granite.Widgets.ModeButton to switch between view modes

            // add a process view
            process_view_window = new Gtk.ScrolledWindow (null, null);
            process_monitor = new ProcessMonitor ();
            app_model = new ApplicationProcessModel (process_monitor);
            process_view = new ProcessView ();
            process_view.set_model (app_model.model);

            // setup search in header bar
            search = new Search (process_view, app_model.model);
            header.pack_end (search);
            this.key_press_event.connect (key_press_event_handler);

            process_view_window.add (process_view);

            sort_model = new Gtk.TreeModelSort.with_model (search.filter_model);
            process_view.set_model (sort_model);

            sidebar = new Sidebar();
            sidebar.width_request = 200;
            sidebar.orientation = Gtk.Orientation.VERTICAL;

            layout = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            layout.pack1 (sidebar, false, false);
            layout.pack2 (process_view_window, false, false);
            layout.position = 200;

            layout.show_all ();
            add (layout);
            this.set_titlebar (header);
        }

        // Handle key presses on window, so that the filter search entry is updated
        private bool key_press_event_handler (Gdk.EventKey event) {
            char typed = event.str[0];

            // if the character typed is an alpha-numeric and the search doesn't currently have focus
            if (typed.isalnum () && !search.is_focus ) {
                search.activate_entry (event.str);
                return true; // tells the window that the event was handled, don't pass it on
            }

            return false; // tells the window that the event wasn't handled, pass it on
        }

        private void kill_process () {
            int pid = process_view.get_pid_of_selected ();
            if (pid > 0) {
                app_model.kill_process (pid);
            }
        }

    }
}

