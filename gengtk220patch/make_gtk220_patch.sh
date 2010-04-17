#!/bin/bash

LANG=C 

find -name "*.c" -o -name "*.h" -o -name "*.cpp" -o -name "*.cxx" | while read f; do
    sed --in-place=.gtk220~ \
	-e 's,GTK_OBJECT_TYPE,G_OBJECT_TYPE,g' \
	-e 's,GTK_OBJECT_TYPE_NAME,G_OBJECT_TYPE_NAME,g' \
	-e 's,GTK_WIDGET_STATE,gtk_widget_get_state,g' \
	-e 's,GTK_WIDGET_TOPLEVEL,gtk_widget_is_toplevel,g' \
	-e 's,GTK_WIDGET_CAN_FOCUS,gtk_widget_get_can_focus,g' \
	-e 's,GTK_WIDGET_CAN_DEFAULT,gtk_widget_get_can_default,g' \
	-e 's,GTK_WIDGET_HAS_DEFAULT,gtk_widget_has_default,g' \
	-e 's,GTK_WIDGET_HAS_GRAB,gtk_widget_has_grab,g' \
	-e 's,GTK_WIDGET_RC_STYLE,gtk_widget_has_rc_style,g' \
	-e 's,GTK_WIDGET_APP_PAINTABLE,gtk_widget_get_app_paintable,g' \
	-e 's,GTK_WIDGET_RECEIVES_DEFAULT,gtk_widget_get_receives_default,g' \
	-e 's,GTK_WIDGET_DOUBLE_BUFFERED,gtk_widget_get_double_buffered,g' \
	-e 's,GTK_WIDGET_VISIBLE,gtk_widget_get_visible,g' \
	-e 's,GTK_WIDGET_HAS_FOCUS,gtk_widget_has_focus,g' \
	-e 's,GTK_WIDGET_REALIZED,gtk_widget_get_realized,g' \
	-e 's,GTK_WIDGET_IS_SENSITIVE,gtk_widget_get_sensitive,g' \
	-e 's,GTK_WIDGET_DRAWABLE,gtk_widget_is_drawable,g' \
	-e 's,GTK_WIDGET_SENSITIVE,gtk_widget_get_sensitive,g' \
	-e 's,GTK_WIDGET_MAPPED,gtk_widget_get_mapped,g' \
	-e 's,GTK_WIDGET_NO_WINDOW,gtk_widget_get_has_window,g' \
    $f

    diff $f $f.gtk220~ > /dev/null
    [ 0 -eq $? ] && rm $f.gtk220~
done


#LANG=C 
#
#CMD=${@:-make}
#
#$CMD
