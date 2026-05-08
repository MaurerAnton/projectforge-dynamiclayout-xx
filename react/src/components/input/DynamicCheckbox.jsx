import React from 'react';
import DynamicLayoutContext from '../../context';

function DynamicCheckbox({ id, label, color, inline, tooltip }) {
    const { data, setData } = React.useContext(DynamicLayoutContext);
    const checked = data && data[id];

    return (
        <div style={{
            display: inline ? 'inline-flex' : 'flex',
            alignItems: 'center',
            marginBottom: '8px',
            marginRight: inline ? '12px' : undefined,
        }}>
            <input
                type="checkbox"
                id={id}
                checked={!!checked}
                onChange={(e) => setData({ [id]: e.target.checked })}
                style={{ marginRight: '6px' }}
            />
            {label && (
                <label htmlFor={id} style={{ margin: 0, fontWeight: 400 }}>
                    {label}
                </label>
            )}
            {tooltip && (
                <span title={tooltip} style={{ marginLeft: '4px', cursor: 'help', color: '#888' }}>ⓘ</span>
            )}
        </div>
    );
}

export default React.memo(DynamicCheckbox);
