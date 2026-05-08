import React from 'react';
import DynamicLayoutContext from '../context';

function contentStructEqual(a, b) {
    if (a === b) return true;
    if (!a || !b) return false;
    if (a.length !== b.length) return false;
    for (let i = 0; i < a.length; i++) {
        if (a[i].key !== b[i].key) return false;
        if (a[i].type !== b[i].type) return false;
    }
    return true;
}

function fieldsetPropsEqual(prev, next) {
    return prev.title === next.title
        && prev.collapsed === next.collapsed
        && contentStructEqual(prev.content, next.content);
}

function DynamicFieldset({ content, title, collapsed }) {
    const { renderLayout } = React.useContext(DynamicLayoutContext);
    const [isOpen, setIsOpen] = React.useState(collapsed !== true);

    return (
        <fieldset style={{
            border: '1px solid #ddd',
            borderRadius: '4px',
            padding: '12px',
            marginBottom: '16px',
        }}>
            {title && (
                <legend
                    style={{
                        fontWeight: 600,
                        fontSize: '1rem',
                        cursor: collapsed !== null && collapsed !== undefined ? 'pointer' : 'default',
                    }}
                    onClick={() => collapsed !== null && collapsed !== undefined && setIsOpen(!isOpen)}
                >
                    {title}
                </legend>
            )}
            {isOpen && renderLayout(content)}
        </fieldset>
    );
}

export default React.memo(DynamicFieldset, fieldsetPropsEqual);
