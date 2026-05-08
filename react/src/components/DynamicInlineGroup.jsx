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

function inlineGroupPropsEqual(prev, next) {
    return contentStructEqual(prev.content, next.content);
}

function DynamicInlineGroup({ content }) {
    const { renderLayout } = React.useContext(DynamicLayoutContext);

    return (
        <div style={{
            display: 'inline-flex',
            gap: '0.5rem',
            alignItems: 'center',
            flexWrap: 'nowrap',
        }}>
            {renderLayout(content)}
        </div>
    );
}

export default React.memo(DynamicInlineGroup, inlineGroupPropsEqual);
