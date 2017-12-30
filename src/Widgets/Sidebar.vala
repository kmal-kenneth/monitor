
using Gtk;

namespace monitor {

    public class Sidebar : Gtk.Box {
        Resources res;
        Label cpu_usage_label;
        Label memory_usage_label;

        public Sidebar () {
            res = new Resources ();
           
            // Memory status
            set_cpu_usage_label ();
            set_memory_usage_label ();

            Timeout.add_seconds (2, () => {
                cpu_usage_label.set_text (("%s %d%%").printf (_("CPU:"), res.get_cpu_usage()));
                memory_usage_label.set_text (("%s %d%%").printf (_("Memory:"), res.get_memory_usage()));
              
                string tooltip_text = ("%.1f %s / %.1f %s").printf (res.used_memory, _("GiB"), res.total_memory, _("GiB"));
                memory_usage_label.tooltip_text = tooltip_text;
                return true;
            });

        }

        private void set_memory_usage_label () {
            string memory_text = ("%s %d%%").printf (_("Memory:"),
                                                     res.get_memory_usage());
            memory_usage_label = new Gtk.Label (memory_text);
            memory_usage_label.margin_left = 12;
            pack_start (memory_usage_label, false, false, 6);
        }

        private void set_cpu_usage_label () {
            string cpu_text = ("%s %d%%").printf (_("CPU:"),
                                                  (int) (res.get_cpu_usage()));
            cpu_usage_label = new Gtk.Label (cpu_text);
            pack_start (cpu_usage_label, false, false, 6);
        }
    }
}
