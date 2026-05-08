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

function groupPropsEqual(prev, next) {
    return prev.type === next.type
        && prev.collapseTitle === next.collapseTitle
        && contentStructEqual(prev.content, next.content);
}

function DynamicGroup({ content, type, collapseTitle }) {
    const { renderLayout } = React.useContext(DynamicLayoutContext);

    let Tag;
    switch (type) {
        case 'COL':
            Tag = 'div';
            break;
        case 'FRAGMENT':
            Tag = React.Fragment;
            break;
        case 'GROUP':
            Tag = 'div';
            break;
        case 'ROW':
            Tag = 'div';
            break;
        default:
            Tag = React.Fragment;
    }

    return (
        <Tag
            style={
                type === 'ROW' ? { display: 'flex', flexWrap: 'wrap' } :
                type === 'GROUP' ? { marginBottom: '0.5rem' } :
                type === 'COL' ? { flex: '1 1 0%', padding: '0 8px' } :
                undefined
            }
        >
            {renderLayout(content)}
        </Tag>
    );
}

export default React.memo(DynamicGroup, groupPropsEqual);
