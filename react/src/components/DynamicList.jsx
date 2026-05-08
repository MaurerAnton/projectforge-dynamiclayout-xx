import React from 'react';
import DynamicLayoutContext from '../context';

function DynamicList({ listId, content, elementVar, positionLabel }) {
    const { data, renderLayout } = React.useContext(DynamicLayoutContext);
    const items = data[listId];

    if (!items || !Array.isArray(items)) return null;

    return (
        <div>
            {items.map((item, index) => (
                <div
                    key={item.id || index}
                    style={{
                        border: '1px solid #dee2e6',
                        borderRadius: '4px',
                        padding: '12px',
                        marginBottom: '8px',
                    }}
                >
                    <div style={{ fontWeight: 600, fontSize: '0.85rem', marginBottom: '8px', color: '#6c757d' }}>
                        {positionLabel || 'Item'} #{index + 1}
                    </div>
                    {renderLayout(content)}
                </div>
            ))}
        </div>
    );
}

export default React.memo(DynamicList);
