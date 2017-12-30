namespace monitor {

    // can't use TreeIter in HashMap for some reason, wrap it in a class
    public class ApplicationProcessRow {
        public Gtk.TreeIter iter;

        public ApplicationProcessRow (Gtk.TreeIter iter) {
            this.iter = iter;
        }
    }

    /**
     * Using a TreeStore (model), describes the relationships between running applications
     * and their processes to be displayed in a TreeView.
     */
    public class ApplicationProcessModel : Object {
        private AppManager app_manager;
        private ProcessMonitor process_monitor;
        private Gee.Map<string, ApplicationProcessRow> app_rows;
        private Gee.Map<int, ApplicationProcessRow> process_rows;
        private Gtk.TreeIter background_apps_iter;

        /**
         * The tree store that will be passed to a TreeView to be displayed.
         */
        public Gtk.TreeStore model { get; private set; }

        /**
         * Constuct an ApplicationProcessModel given a ProcessMonitor
         */
        public ApplicationProcessModel (ProcessMonitor _monitor) {
            process_monitor = _monitor;

            model = new Gtk.TreeStore (
                ProcessColumns.NUM_COLUMNS,
                typeof (string),
                typeof (string),
                typeof (int),
                typeof (double),
                typeof (int64)
                );

            set_background_apps ();

            // The Great App Manager
            app_manager = AppManager.get_default ();
            app_manager.application_opened.connect (handle_application_opened);
            app_manager.application_closed.connect (handle_application_closed);

            app_rows = new Gee.HashMap<string, ApplicationProcessRow> ();
            process_rows = new Gee.HashMap<int, ApplicationProcessRow> ();


            // handle processes being added and removed
            process_monitor.process_added.connect (handle_process_added);
            process_monitor.process_removed.connect (handle_process_removed);
            process_monitor.updated.connect (handle_monitor_update);

            // run when application is done loading to populate list
            Idle.add (() => { add_running_applications (); return false; } );
            Idle.add (() => { add_running_processes (); return false; } );

        }

        private void set_background_apps () {
            model.append (out background_apps_iter, null);
            model.set (background_apps_iter,
                ProcessColumns.NAME, _("Background Applications"),
                ProcessColumns.ICON, "system-run",
                ProcessColumns.MEMORY, (uint64)0,
                ProcessColumns.CPU, -4.0,
                -1);
        }

        private void update_app_row (Gtk.TreeIter iter) {
            int64 total_mem = 0;
            double total_cpu = 0;
            get_children_total (iter, ref total_mem, ref total_cpu);
            model.set (iter, ProcessColumns.MEMORY, total_mem,
                                                ProcessColumns.CPU, total_cpu,
                                                -1);
        }

        // Handles a updated signal from ProcessMonitor by refreshing all of the process rows in the list
        private void handle_monitor_update () {
            foreach (var pid in process_rows.keys) {
                update_process (pid);
            }

            foreach (var desktop_file in app_rows.keys) {
                update_application (desktop_file);
            }
            update_app_row (background_apps_iter);
        }

        // Handles a process-added signal from ProcessMonitor by adding the process to our list
        private void handle_process_added (int pid, Process process) {
            //debug ("Handle: Process Added %d ".printf(pid));
            add_process (pid);
        }

        // Handles a process-removed signal from ProcessMonitor by removing the process from our list
        private void handle_process_removed (int pid) {
            //debug ("Handle: Process Removed %d".printf(pid));
            remove_process (pid);
        }

        /**
         * Handle the application-opened signal and add an application to the list when it is opened
         */
        private void handle_application_opened (App app) {
            //debug ("Handle: Application Opened");
            add_application (app);
            // update the application columns
            update_application (app.desktop_file);
        }

        // Handle the application-closed signal and remove an application from the list when it is closed
        private void handle_application_closed (App app) {
            //debug ("Handle: Application Closed");
            remove_application (app);
        }

        // Adds all running applications to the list.
        private void add_running_applications () {
            //debug ("add_running_applications");
            // get all running applications and add them to the tree store
            var running_applications = app_manager.get_running_applications ();
            foreach (var app in running_applications) {
                add_application (app);
            }
        }

        /**
         * Adds all running processes to the list.
         */
        private void add_running_processes () {
            //debug ("add_running_processes");
            var running_processes = process_monitor.get_process_list ();
            foreach (var pid in running_processes.keys) {
                add_process (pid);
            }
        }

        // Adds an application to the list
        private void add_application (App app) {
            if (app_rows.has_key (app.desktop_file)) {
                // App already in application rows, no need to add
                //debug ("Skip App");
                return;
            }
            // add the application to the model
            Gtk.TreeIter iter;
            model.append (out iter, null);
            model.set (iter,
                ProcessColumns.NAME, app.name,
                ProcessColumns.ICON, app.icon,
                -1);

            // add the application to our cache of app_rows
            var row = new ApplicationProcessRow (iter);
            app_rows.set (app.desktop_file, row);

            // go through the windows of the application and add all of the pids
            for (var i = 0; i < app.pids.length; i++) {
                //debug ("Add App: %s %d", app.name, app.pids[i]);
                add_process_to_row (iter, app.pids[i]);
                // adds pid to application
                model.set (iter, ProcessColumns.PID, app.pids[i]);
            }
        }

        private void get_children_total (Gtk.TreeIter iter, ref int64 memory, ref double cpu) {
            // go through all children and add up CPU/Memory usage
            // TODO: this is a naive way to do things
            Gtk.TreeIter child_iter;

            if (model.iter_children (out child_iter, iter)) {
                do {
                    get_children_total (child_iter, ref memory, ref cpu);
                    Value cpu_value;
                    Value memory_value;
                    model.get_value (child_iter, ProcessColumns.CPU, out cpu_value);
                    model.get_value (child_iter, ProcessColumns.MEMORY, out memory_value);
                    memory += memory_value.get_int64 ();
                    cpu += cpu_value.get_double ();
                } while (model.iter_next (ref child_iter));
            }
        }

        private void update_application (string desktop_file) {
            if (!app_rows.has_key (desktop_file))
                return;

            var app_iter = app_rows[desktop_file].iter;
            update_app_row (app_iter);
        }

        /**
         * Removes an application from the list.
         */
        private bool remove_application (App app) {
            //debug ("Remove App: %s", app.name);

            // check if desktop file is in our row cache
            if (!app_rows.has_key (app.desktop_file)) {
                return false;
            }
            var app_iter = app_rows[app.desktop_file].iter;

            // reparent children to background processes; let the ProcessMonitor take care of removing them
            Gtk.TreeIter child_iter;
            while (model.iter_children (out child_iter, app_iter)) {
                Value pid_value;
                model.get_value (child_iter, ProcessColumns.PID, out pid_value);
                //debug ("Reparent Process to Background: %d", pid_value.get_int ());
                add_process_to_row (background_apps_iter, pid_value.get_int ());
            }

            // remove row from model
            model.remove (ref app_iter);

            // remove row from row cache
            app_rows.unset (app.desktop_file);

            return true;
        }

        // Adds a process by pid, making sure to parent it to the right process
        private bool add_process (int pid) {
            //debug ("add_process %d", pid);
            if (process_rows.has_key (pid)) {
                // process already in process rows, no need to add
                //debug ("Skipping Add Process %d", pid);
                return false;
            }

            var process = process_monitor.get_process (pid);

            if (process != null && process.pid != 1) {
                //debug ("Parent PID: %d", process.ppid);
                if (process.ppid > 1) {
                    // is a sub process of something
                    if (process_rows.has_key (process.ppid)) {
                        // is a subprocess of something in the rows
                        add_process_to_row (process_rows[process.ppid].iter, pid);
                    } else {
                        add_process_to_row (background_apps_iter, pid);
                        //debug ("Is a subprocess of something but has no parent");
                    }
                    // if parent not in yet, then child will be added in after
                } else {
                    // isn't a subprocess of something, put it into background processes
                    // it can be moved afterwards to an application
                    add_process_to_row (background_apps_iter, pid);
                }

                return true;
            }

            return false;
        }

        // Addes a process to an existing row; reparenting it and it's children it it already exists.
        private bool add_process_to_row (Gtk.TreeIter row, int pid) {
            var process = process_monitor.get_process (pid);
            //debug ("add_process_to_row %d", pid);

            if (process != null) {
                // if process is already in list, then we need to reparent it and it's children
                // can't remove it now because we need to remove all of the children first.
                Gtk.TreeIter? old_location = null;
                if (process_rows.has_key (pid)) {
                    old_location = process_rows[pid].iter;
                }

                // add the process to the model
                Gtk.TreeIter iter;
                model.append (out iter, row);
                model.set (iter, ProcessColumns.NAME, process.command,
                                 ProcessColumns.ICON, "application-x-executable",
                                 ProcessColumns.PID, process.pid,
                                 ProcessColumns.CPU, process.cpu_usage,
                                 ProcessColumns.MEMORY, process.mem_usage,
                                 -1);

                // add the process to our cache of process_rows
                var process_row = new ApplicationProcessRow (iter);
                process_rows.set (pid, process_row);

                // add all subprocesses to this row, recursively
                var sub_processes = process_monitor.get_sub_processes (pid);
                foreach (var sub_pid in sub_processes) {
                    // only add subprocesses that either arn't in yet or are parented to the old location
                    // i.e. skip if subprocess is already in but isn't an ancestor of this process row
                    if (process_rows.has_key (sub_pid) && (
                             (old_location != null && !model.is_ancestor (old_location, process_rows[sub_pid].iter))
                             || old_location == null))
                        continue;

                    add_process_to_row (iter, sub_pid);
                }

                // remove old row where the process used to be
                if (old_location != null) {
                    model.remove (ref old_location);
                }

                return true;
            }

            return false;
        }

        // Removes a process from the model by pid
        private void remove_process (int pid) {
            //debug ("remove process %d".printf(pid));
            // if process rows has pid
            if (process_rows.has_key (pid)) {
                var row = process_rows.get (pid);
                var iter = row.iter;

                // reparent children to background processes; let the ProcessMonitor take care of removing them
                Gtk.TreeIter child_iter;
                while (model.iter_children (out child_iter, iter)) {
                    Value pid_value;
                    model.get_value (child_iter, ProcessColumns.PID, out pid_value);
                    add_process_to_row (background_apps_iter, pid_value.get_int ());
                }

                // remove row from model
                model.remove (ref iter);

                // remove row from row cache
                process_rows.unset (pid);
            }
        }

        // Updates a process by pid
        private void update_process (int pid) {
            var process = process_monitor.get_process (pid);

            if (process_rows.has_key (pid) && process != null) {
                Gtk.TreeIter process_iter = process_rows[pid].iter;
                model.set (process_iter, 
                                ProcessColumns.CPU, process.cpu_usage,
                                ProcessColumns.MEMORY, process.mem_usage,
                                 -1);
            }
        }

        public void kill_process (int pid) {
            var process = process_monitor.get_process (pid);
            process.kill ();
            info ("Kill:%d",process.pid);
        }
    }
}
