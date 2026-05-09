// Demo: generate DynamicLayout JSON from C
// Build: gcc -o demo demo.c
// Run:   ./demo

#include <stdio.h>
#include <string.h>
#include "../../dynamiclayout.h"

int main() {
    char buf[16384];

    // === About page ===
    DL b = dl_begin(buf, sizeof(buf), "About Page (C)");
    dl_section(&b, "About", "DynamicLayout Engine v1.0");
    dl_section(&b, "License", "GPLv3");
    dl_end(&b);
    printf("=== About ===\n%s\n", buf);

    // === Form with all element types ===
    DL b2 = dl_begin(buf, sizeof(buf), "Full Demo (C)");

    dl_fieldset(&b2, "Form Demo");
    dl_input(&b2, "name", "Your Name");
    dl_input(&b2, "email", "Email");

    const char *cid[] = {"us","de","jp","gb"};
    const char *clbl[] = {"USA","Germany","Japan","UK"};
    dl_select(&b2, "country", "Country", cid, clbl, 4);

    dl_checkbox(&b2, "agree", "I agree to terms");
    dl_textarea(&b2, "notes", "Notes", 4);
    dl_end_fieldset(&b2);

    dl_alert(&b2, "All fields are required", "info");

    dl_actions(&b2);
    dl_button(&b2, "submit", "Submit", "primary");
    dl_button(&b2, "cancel", "Cancel", "secondary");
    dl_end_actions(&b2);

    dl_end(&b2);
    printf("=== Full Form ===\n%s\n", buf);

    // Validation
    if (strstr(buf, "FIELDSET") && strstr(buf, "INPUT") && strstr(buf, "SELECT")
        && strstr(buf, "CHECKBOX") && strstr(buf, "ALERT")) {
        printf("=== All checks PASSED ===\n");
        return 0;
    } else {
        printf("=== Some checks FAILED ===\n");
        return 1;
    }
}
