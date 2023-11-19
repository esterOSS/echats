namespace Xmpp {

public class StanzaWriter {
    public signal void cancel();

    private OutputStream output;

    private Queue<SourceFuncWrapper> queue = new Queue<SourceFuncWrapper>();
    private bool running = false;

    public StanzaWriter.for_stream(OutputStream output) {
        this.output = output;
    }

    public async void write_node(StanzaNode node, int io_priority = Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        yield write_data(node.to_xml().data, io_priority, cancellable);
    }

    public async void write_nodes(StanzaNode node1, StanzaNode node2, int io_priority = Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        var data1 = node1.to_xml().data;
        var data2 = node2.to_xml().data;

        uint8[] concat = new uint8[data1.length + data2.length];
        int i = 0;
        foreach (var datum in data1) {
            concat[i++] = datum;
        }
        foreach (var datum in data2) {
            concat[i++] = datum;
        }

        yield write_data(concat, io_priority, cancellable);
    }

    public async void write(string s, int io_priority = Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        yield write_data(s.data, io_priority, cancellable);
    }

    private async void write_data(owned uint8[] data, int io_priority = Priority.DEFAULT, Cancellable? cancellable = null) throws IOError {
        if (running) {
            queue.push_tail(new SourceFuncWrapper(write_data.callback));
            yield;
        }
        running = true;
        try {
            yield output.write_all_async(data, io_priority, cancellable, null);
        } catch (IOError e) {
            cancel();
            throw e;
        } catch (GLib.Error e) {
            cancel();
            throw new IOError.FAILED("Error in GLib: %s".printf(e.message));
        } finally {
            SourceFuncWrapper? sfw = queue.pop_head();
            if (sfw != null) {
                sfw.sfun();
            } else {
                running = false;
            }
        }
    }
}

public class SourceFuncWrapper : Object {

    public SourceFunc sfun;

    public SourceFuncWrapper(owned SourceFunc sfun) {
        this.sfun = (owned)sfun;
    }
}

}
