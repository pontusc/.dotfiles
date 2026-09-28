theme:
    colors:
        text:
            primary: "{{ foreground }}"
            secondary: "{{ muted }}"
            inverted: "{{ background }}"
            faint: "{{ mix background foreground 45% }}"
            warning: "{{ red }}"
            success: "{{ green }}"
            error: "{{ bright_red }}"
            actor: "{{ accent }}"
        background:
            selected: "{{ selection_background }}"
        border:
            primary: "{{ accent }}"
            secondary: "{{ muted }}"
            faint: "{{ lighter_background }}"
        icon:
            newcontributor: "{{ cyan }}"
            contributor: "{{ blue }}"
            collaborator: "{{ yellow }}"
            member: "{{ yellow }}"
            owner: "{{ orange }}"
            unknownrole: "{{ muted }}"
