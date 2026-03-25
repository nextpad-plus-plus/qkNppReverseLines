/*
 * Reverse Lines plugin for Notepad++ macOS
 * Ported from qkNppReverseLines by Query Kuma
 *
 * Original: https://github.com/querykuma/qkNppReverseLines
 * License: GPLv3
 */

#include "NppPluginInterfaceMac.h"
#include "Scintilla.h"

#import <Cocoa/Cocoa.h>
#include <cstring>
#include <cstdlib>

// ── Plugin state ────────────────────────────────────────────────────────

static const char *PLUGIN_NAME = "Reverse Lines";
static const int NB_FUNC = 3;
static FuncItem funcItem[NB_FUNC];
static NppData nppData;

// ── Forward declarations ────────────────────────────────────────────────

static void reverseSelection();
static void reverseDocument();
static void aboutDlg();

// ── Helpers ─────────────────────────────────────────────────────────────

static NppHandle getCurScintilla()
{
    int which = -1;
    nppData._sendMessage(nppData._nppHandle, NPPM_GETCURRENTSCINTILLA, 0, (intptr_t)&which);
    if (which == -1)
        return 0;
    return (which == 0) ? nppData._scintillaMainHandle : nppData._scintillaSecondHandle;
}

static intptr_t sci(NppHandle h, uint32_t msg, uintptr_t w = 0, intptr_t l = 0)
{
    return nppData._sendMessage(h, msg, w, l);
}

// ── Core algorithm ──────────────────────────────────────────────────────
// eol_mode: 0 = CRLF, 1 = CR, 2 = LF

static void reverseLines(size_t bufLength, const char *selectedText, char *reversedText, size_t eol_mode)
{
    size_t cpy_len = 0;
    char eol = (eol_mode == 1) ? '\r' : '\n';

    for (size_t i = 0; i <= bufLength - 1; i++) {
        size_t j = bufLength - 1 - i;
        size_t i_move = i;
        char c = selectedText[i];

        if (c == eol) {
            i_move -= cpy_len;

            if (eol_mode == 0) {
                reversedText[j++] = '\r';
                cpy_len -= 1;
            }
            reversedText[j++] = eol;
            strncpy(reversedText + j, selectedText + i_move, cpy_len);
            cpy_len = 0;
        } else {
            cpy_len++;
        }
    }

    if (cpy_len != 0) {
        strncpy(reversedText, selectedText + bufLength - cpy_len, cpy_len);
    }
}

// ── Commands ────────────────────────────────────────────────────────────

static void reverseSelection()
{
    NppHandle h = getCurScintilla();
    if (!h) return;

    size_t eol_mode = (size_t)sci(h, SCI_GETEOLMODE);
    size_t bufLength = (size_t)sci(h, SCI_GETSELTEXT);
    if (bufLength < 2) return;

    char *selectedText = new char[bufLength];
    char *reversedText = new char[bufLength];
    sci(h, SCI_GETSELTEXT, 0, (intptr_t)selectedText);

    bufLength = strlen(selectedText);
    reverseLines(bufLength, selectedText, reversedText, eol_mode);

    size_t selStart = (size_t)sci(h, SCI_GETSELECTIONSTART);
    size_t selEnd   = (size_t)sci(h, SCI_GETSELECTIONEND);
    if (selEnd < selStart) {
        size_t tmp = selStart;
        selStart = selEnd;
        selEnd = tmp;
    }
    sci(h, SCI_SETTARGETSTART, selStart);
    sci(h, SCI_SETTARGETEND, selEnd);
    sci(h, SCI_REPLACETARGET, bufLength, (intptr_t)reversedText);
    sci(h, SCI_SETSEL, selStart, (intptr_t)(selStart + bufLength));

    delete[] reversedText;
    delete[] selectedText;
}

static void reverseDocument()
{
    NppHandle h = getCurScintilla();
    if (!h) return;

    size_t curPos      = (size_t)sci(h, SCI_GETCURRENTPOS);
    size_t text_length = (size_t)sci(h, SCI_GETTEXTLENGTH);

    sci(h, SCI_SELECTALL);
    reverseSelection();
    sci(h, SCI_SETSEL, (uintptr_t)-1, (intptr_t)(text_length - curPos));
}

static void aboutDlg()
{
    @autoreleasepool {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"About Reverse Lines";
        alert.informativeText = @"Author: Query Kuma\nVersion: 1.0.0.0";
        alert.icon = [[NSImage alloc] initWithSize:NSMakeSize(1, 1)];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
}

// ── Plugin exports ──────────────────────────────────────────────────────

extern "C" NPP_EXPORT void setInfo(NppData data)
{
    nppData = data;

    // Set up menu items
    strlcpy(funcItem[0]._itemName, "Selection", NPP_MENU_ITEM_SIZE);
    funcItem[0]._pFunc = reverseSelection;
    funcItem[0]._init2Check = false;
    funcItem[0]._pShKey = nullptr;

    strlcpy(funcItem[1]._itemName, "Document", NPP_MENU_ITEM_SIZE);
    funcItem[1]._pFunc = reverseDocument;
    funcItem[1]._init2Check = false;
    funcItem[1]._pShKey = nullptr;

    strlcpy(funcItem[2]._itemName, "About", NPP_MENU_ITEM_SIZE);
    funcItem[2]._pFunc = aboutDlg;
    funcItem[2]._init2Check = false;
    funcItem[2]._pShKey = nullptr;
}

extern "C" NPP_EXPORT const char *getName()
{
    return PLUGIN_NAME;
}

extern "C" NPP_EXPORT FuncItem *getFuncsArray(int *nbF)
{
    *nbF = NB_FUNC;
    return funcItem;
}

extern "C" NPP_EXPORT void beNotified(SCNotification *notifyCode)
{
    switch (notifyCode->nmhdr.code) {
        case NPPN_SHUTDOWN:
            break;
        default:
            break;
    }
}

extern "C" NPP_EXPORT intptr_t messageProc(uint32_t /*msg*/, uintptr_t /*wParam*/, intptr_t /*lParam*/)
{
    return 1; // TRUE
}
