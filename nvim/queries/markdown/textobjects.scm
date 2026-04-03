; extends

; ATX headings (# style)
(atx_heading) @heading.outer
(atx_heading
  heading_content: (_) @heading.inner) @heading.outer

; Setext headings (underline style)
(setext_heading) @heading.outer
(setext_heading
  heading_content: (_) @heading.inner) @heading.outer

; Sections (content between headings)
(section) @section.outer