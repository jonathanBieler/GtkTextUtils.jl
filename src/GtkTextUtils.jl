module GtkTextUtils

    using Gtk, GtkExtensions, JuliaWordsUtils
    import Gtk: GtkTextIter, GLib.mutable, hasselection
    import JuliaWordsUtils: select_word_backward

    export select_word_double_click, select_word, get_line_text, cursor_position,
    get_text_iter_at_cursor, get_current_line_text,
    get_text_left_of_iter, get_text_right_of_iter,
    move_cursor_to_sentence_start, move_cursor_to_sentence_end,
    hasselection,replace_text

    function hasselection(b::GtkTextBuffer)
        (found,it_start,it_end) = selection_bounds(b)
        found
    end
    function replace_text(buffer::GtkTextBuffer,itstart::T,itend::T,str::AbstractString) where {T<:GtkTextIters}
        pos = offset(itstart)+1
        splice!(buffer,itstart:itend)
        insert!(buffer,GtkTextIter(buffer,pos),str)
    end

    cursor_position(b::GtkTextBuffer) = get_gtk_property(b,:cursor_position,Int)

    get_text_iter_at_cursor(b::GtkTextBuffer) =
        GtkTextIter(b,cursor_position(b)+1) #+1 because there's a -1 in gtk.jl

    function get_current_line_text(buffer::GtkTextBuffer)
        it = get_text_iter_at_cursor(buffer)
        return get_line_text(buffer,it)
    end

    function select_word(it::GtkTextIter,buffer::GtkTextBuffer,stop_at_dot::Bool)

        (txt, line_start, line_end) = get_line_text(buffer,it)

        pos = offset(it) - offset(line_start) +1#not sure about the +1 but it feels better
        if pos <= 0
            return ("",GtkTextIter(buffer,offset(it)),
            GtkTextIter(buffer,offset(it)))
        end

        word,i,j = extend_word(pos, txt, stop_at_dot)

        its = GtkTextIter(buffer, i + offset(line_start) )
        ite = GtkTextIter(buffer, j + offset(line_start) + 1)

        return (word,its,ite)
    end
    select_word(it::GtkTextIter,buffer::GtkTextBuffer) = select_word(it,buffer,true)

    function select_word_backward(it::GtkTextIter,buffer::GtkTextBuffer,stop_at_dot::Bool)

        (txt, line_start, line_end) = get_line_text(buffer,it)
        pos = offset(it) - offset(line_start) #position of cursor in txt

        if pos <= 0 || length(txt) == 0
            return ("",GtkTextIter(buffer,offset(it)),
            GtkTextIter(buffer,offset(it)))
        end

        txt = CharArray(txt,pos)
        (i,j) = select_word_backward(pos,txt,stop_at_dot)

        its = GtkTextIter(buffer, i + offset(line_start) )
        ite = GtkTextIter(buffer, offset(it))

        return (txt[i:j],its,it)
    end

    function get_line_text(buffer::GtkTextBuffer,it::GtkTextIter)

        itstart, itend = mutable(it), mutable(it)
        li = get_gtk_property(itstart,:line,Integer)

        text_iter_backward_line(itstart)#seems there's no skip to line start
        li != get_gtk_property(itstart,:line,Integer) && skip(itstart,1,:line)#for fist line
        !get_gtk_property(itend,:ends_line,Bool) && text_iter_forward_to_line_end(itend)

        return ( (itstart:itend).text[String], itstart, itend)
    end

    function select_word_double_click(textview::GtkTextView,buffer::GtkTextBuffer,x::Integer,y::Integer)

        (x,y) = text_view_window_to_buffer_coords(textview,x,y)
        iter_end = get_iter_at_position(textview,x,y)
        #iter_end = mutable( get_text_iter_at_cursor(buffer) ) #not using this because the cursor position is modified somewhere

        (w, iter_start, iter_end) = select_word(iter_end,buffer)
        selection_bounds(buffer,iter_start,iter_end)
    end

    function get_text_right_of_cursor(buffer::GtkTextBuffer)
        it = mutable(get_text_iter_at_cursor(buffer))
        return (it:(it+1)).text[String] 
    end
    function get_text_left_of_cursor(buffer::GtkTextBuffer)
        it = mutable(get_text_iter_at_cursor(buffer))
        return ((it-1):it).text[String]
    end

    get_text_left_of_iter(it::MutableGtkTextIter) = ((it-1):it).text[String]
    get_text_right_of_iter(it::MutableGtkTextIter) = (it:(it+1)).text[String]

    get_text_left_of_iter(it::GtkTextIter) = ((mutable(it)-1):mutable(it)).text[String]
    get_text_right_of_iter(it::GtkTextIter) = (mutable(it):(mutable(it)+1)).text[String]

    nlines(it_start,it_end) = abs(line(it_end)-line(it_start))+1

    function move_cursor_to_sentence_start(buffer::GtkTextBuffer)
        it = mutable( get_text_iter_at_cursor(buffer) )
        text_iter_backward_sentence_start(it)
        text_buffer_place_cursor(buffer,it)
    end
    function move_cursor_to_sentence_end(buffer::GtkTextBuffer)
        it = mutable( get_text_iter_at_cursor(buffer) )
        text_iter_forward_sentence_end(it)
        text_buffer_place_cursor(buffer,it)
    end

    function toggle_wrap_mode(v::GtkTextView)
        wm = get_gtk_property(v,:wrap_mode,Int)
        wm = convert(Bool,wm)
        setproperty!(v,:wrap_mode,!wm)
        nothing
    end

end # module
