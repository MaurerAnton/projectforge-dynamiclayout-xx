<?php
/**
 * DynamicLayout PHP API — generate layout JSON from PHP code.
 *
 * Single-file. Zero dependencies (json_encode is built-in).
 * Works on PHP 7.4+.
 *
 * Example:
 *   $page = Layout::begin('My Page');
 *   $page->fieldset('Info')->label('Hello from PHP!')->end();
 *   $page->button('ok', 'OK', 'primary', true);
 *   echo $page->end();
 */

class Layout {
    private string $title;
    private string $uid;
    private array $layout = [];
    private array $actions = [];
    private array $stack = [];
    private int $counter = 0;

    private function __construct(string $title) {
        $this->title = $title;
        $this->uid = 'layout_' . hrtime(true);
        $this->stack[] = &$this->layout;
    }

    public static function begin(string $title): self { return new self($title); }

    private function k(string $prefix): string { return $prefix . '_' . (++$this->counter); }

    private function &top(): array & { return $this->stack[count($this->stack) - 1]; }

    private function add(array $el): self { $this->top()[] = $el; return $this; }

    private function push(array $el): self {
        $el['content'] = []; $this->add($el); $this->stack[] = &$this->top()[count($this->top()) - 1]['content'];
        return $this;
    }

    private function pop(): self { array_pop($this->stack); return $this; }

    // Containers
    public function fieldset(string $title): self { return $this->push(['type' => 'FIELDSET', 'key' => $this->k('fs'), 'title' => $title]); }
    public function end(): self { return $this->pop(); }
    public function row(): self { return $this->push(['type' => 'ROW', 'key' => $this->k('r')]); }
    public function endRow(): self { return $this->pop(); }
    public function col(int $xs = 0, int $sm = 0, int $md = 0, int $lg = 0, int $xl = 0): self {
        $el = ['type' => 'COL', 'key' => $this->k('c')];
        $len = []; if ($xs) $len['xs'] = $xs; if ($sm) $len['sm'] = $sm; if ($md) $len['md'] = $md; if ($lg) $len['lg'] = $lg; if ($xl) $len['xl'] = $xl;
        if ($len) $el['length'] = $len;
        return $this->push($el);
    }
    public function endCol(): self { return $this->pop(); }

    // Display
    public function label(string $text): self { return $this->add(['type' => 'LABEL', 'key' => $this->k('l'), 'label' => $text]); }
    public function alert(string $message, string $color = 'info'): self { return $this->add(['type' => 'ALERT', 'key' => $this->k('a'), 'message' => $message, 'color' => $color]); }
    public function badge(string $title, string $color = 'primary'): self { return $this->add(['type' => 'BADGE', 'key' => $this->k('bd'), 'title' => $title, 'color' => $color]); }
    public function spacer(int $px = 20): self { return $this->add(['type' => 'SPACER', 'key' => $this->k('sp'), 'width' => $px]); }

    // Inputs
    public function input(string $id, string $label = '', bool $required = false, string $dataType = 'STRING'): self {
        $el = ['type' => 'INPUT', 'key' => $this->k('i'), 'id' => $id, 'label' => $label];
        if ($required) $el['required'] = true; if ($dataType !== 'STRING') $el['dataType'] = $dataType;
        return $this->add($el);
    }
    public function textarea(string $id, string $label = '', int $rows = 3): self { return $this->add(['type' => 'TEXTAREA', 'key' => $this->k('ta'), 'id' => $id, 'label' => $label, 'rows' => $rows]); }
    public function checkbox(string $id, string $label = ''): self { return $this->add(['type' => 'CHECKBOX', 'key' => $this->k('cb'), 'id' => $id, 'label' => $label]); }
    public function select(string $id, string $label, array $pairs): self {
        $vals = array_map(fn($p) => ['id' => $p[0], 'displayName' => $p[1]], $pairs);
        return $this->add(['type' => 'SELECT', 'key' => $this->k('s'), 'id' => $id, 'label' => $label, 'values' => $vals]);
    }
    public function rating(string $id, string $label = ''): self { return $this->add(['type' => 'RATING', 'key' => $this->k('rt'), 'id' => $id, 'label' => $label]); }
    public function readonly(string $id, string $label = ''): self { return $this->add(['type' => 'READONLY_FIELD', 'key' => $this->k('ro'), 'id' => $id, 'label' => $label]); }

    // Actions
    public function button(string $id, string $title, string $color = 'primary', bool $isDefault = false): self {
        $el = ['type' => 'BUTTON', 'key' => $this->k('btn'), 'id' => $id, 'title' => $title, 'color' => $color];
        if ($isDefault) $el['default'] = true;
        $this->actions[] = $el; return $this;
    }

    // Shortcuts
    public function section(string $title, string $text): self { return $this->fieldset($title)->label($text)->end(); }
    public function feedbackForm(): self {
        return $this->fieldset('Your Details')
            ->input('name', 'Name', true)
            ->input('email', 'Email', true)
            ->textarea('message', 'Message', 5)
            ->end()
            ->button('send', 'Send', 'primary', true)
            ->button('cancel', 'Cancel', 'secondary');
    }

    // Output
    public function toArray(): array {
        while (count($this->stack) > 1) $this->pop();
        $ui = ['title' => $this->title, 'uid' => $this->uid, 'layout' => $this->layout, 'translations' => (object)[], 'userAccess' => ['cancel' => true]];
        if (!empty($this->actions)) $ui['actions'] = $this->actions;
        return ['ui' => $ui];
    }
    public function toJSON(): string { return json_encode($this->toArray(), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE); }
    public function __toString(): string { return $this->toJSON(); }
}
