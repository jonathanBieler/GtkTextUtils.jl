using GtkTextUtils, Gtk
import GtkTextUtils: offset

@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

import Gtk: GtkTextIter, GLib.mutable, hasselection

w = GtkWindow()
b = GtkTextBuffer()
b.text[String] = "test"
v = GtkTextView(b)

push!(w,v)
showall(w)

begin
    it = GtkTextIter(b)
    get_gtk_property(it,:line,Int64)
end

word, its, ite = get_current_line_text(b)
@test word == "test"
@test offset(its) == 0
@test offset(ite) == 4

word,its,ite = select_word(GtkTextIter(b),b,false)
str="test2"

function replace_text2(b::GtkTextBuffer,its,ite,str::AbstractString)
    pos = offset(its)+1
    splice!(b,its:ite)
    insert!(b,GtkTextIter(b,pos),str)
end

replace_text2(b,its,ite,"test2")

word, its, ite = get_current_line_text(b)
@test word == "test2"

destroy(w)