#include <gtk/gtk.h>

GtkWidget *entry;
GtkWidget *label;

void on_button_clicked(GtkWidget *widget, gpointer data) {
    const char *name = gtk_entry_get_text(GTK_ENTRY(entry));
    char message[200];

    if (name[0] == '\0') {
        gtk_label_set_text(GTK_LABEL(label), "Please enter your name");
    } else {
        sprintf(message, "Hello, %s! GTK3 is working.", name);
        gtk_label_set_text(GTK_LABEL(label), message);
    }
}

int main(int argc, char *argv[]) {
    gtk_init(&argc, &argv);

    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window), "GTK3 Test");
    gtk_window_set_default_size(GTK_WINDOW(window), 350, 200);
    gtk_container_set_border_width(GTK_CONTAINER(window), 15);
    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);

    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 10);
    gtk_container_add(GTK_CONTAINER(window), box);

    entry = gtk_entry_new();
    gtk_entry_set_placeholder_text(GTK_ENTRY(entry), "Enter your name");
    gtk_box_pack_start(GTK_BOX(box), entry, FALSE, FALSE, 0);

    GtkWidget *button = gtk_button_new_with_label("Say Hello");
    g_signal_connect(button, "clicked", G_CALLBACK(on_button_clicked), NULL);
    gtk_box_pack_start(GTK_BOX(box), button, FALSE, FALSE, 0);

    label = gtk_label_new("Waiting for input...");
    gtk_box_pack_start(GTK_BOX(box), label, TRUE, TRUE, 0);

    gtk_widget_show_all(window);
    gtk_main();

    return 0;
}
