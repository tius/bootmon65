;   macros_align.inc  
;
;   useful macros to check alignment and memory page crossing
;
;   credits:
;       - https://forums.nesdev.org/viewtopic.php?t=14622
;
;------------------------------------------------------------------------------
;   MIT License
;
;   Copyright (c) 1978-2025 Matthias Waldorf, https://tius.org
;
;   Permission is hereby granted, free of charge, to any person obtaining a copy
;   of this software and associated documentation files (the "Software"), to deal
;   in the Software without restriction, including without limitation the rights
;   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;   copies of the Software, and to permit persons to whom the Software is
;   furnished to do so, subject to the following conditions:
;
;   The above copyright notice and this permission notice shall be included in all
;   copies or substantial portions of the Software.
;
;   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;   SOFTWARE.
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;   make sure, that address is aligned to a given size

.macro ASSERT_ALIGNMENT addr, size
    .assert (addr .mod size) = 0, error, "alignment error!"
.endmacro

;------------------------------------------------------------------------------
;   make sure that branch does not cross page

.macro ASSERT_BRANCH_PAGE cmd, label_
    cmd label_
    .assert >(label_) = >*, error, "page crossing branch!"
.endmacro

;------------------------------------------------------------------------------
;   make sure, that two addresses are in the same memory page

.macro ASSERT_SAME_PAGE addr1, addr2
    .assert >(addr1) = >(addr2), error, "page crossing detected!"
.endmacro
