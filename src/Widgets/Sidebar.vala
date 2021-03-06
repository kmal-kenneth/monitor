using Gtk;

namespace monitor {
    
    public class Sidebar : Gtk.Box {
        private Resources resources;
        
	    // wigets
	    private Label cpu_usage;
	    private Label memory_usage;
	    private Label memory_usage_detail;
	    
	    // text for widgets
	    string cpu_usage_text;
	    string memory_usage_text;
	    string memory_usage_detail_text;

     	public Sidebar () {
     		Object (orientation : Orientation.VERTICAL, width_request : 200);
     		
     		update_text_data ();
     	}

     	construct {
     		resources = new Resources ();
     		
     		// cpu data
     		cpu_usage_text = ("%s %d%%").printf (_("CPU:"), (int) resources.get_cpu_usage ());
     		cpu_usage = new Label (cpu_usage_text);
     		
     		// memory data
     		memory_usage_text = ("%s %d%%").printf (_("Memory:"), (int) resources.get_memory_usage ());
     		memory_usage = new Label (memory_usage_text);
     		
     		memory_usage_detail_text = ("%.1f %s / %.1f %s").printf (resources.used_memory, _("GiB"), resources.total_memory, _("GiB"));
     		memory_usage_detail = new Label (memory_usage_detail_text);
     		
     		pack_start (cpu_usage, false, false, 6);
     		pack_start (memory_usage, false, false, 6);
     		pack_start (memory_usage_detail, false, false, 6);
     	}
     	
     	private void update_text_data () {
     	    Timeout.add_seconds (1, () => {
     	        cpu_usage.set_text (("%s %d%%").printf (_("CPU:"), resources.get_cpu_usage()));
     	        memory_usage.set_text (("%s %d%%").printf (_("Memory:"), resources.get_memory_usage()));
     	        memory_usage_detail.set_text (("%.1f %s / %.1f %s").printf (resources.used_memory, _("GiB"), resources.total_memory, _("GiB")));
                return true;
            });
     	}
    }
}
