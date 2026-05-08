import React from 'react';
import DynamicLayoutContext from '../../context';

function DynamicRadioButton({ id, name, value, label, tooltip }) {
    const { data, setData } = React.useContext(DynamicLayoutContext);
    const checked = data && data[id] === value;

    return (
        <div style={{ display: 'flex', alignItems: 'center', marginBottom: '4px' }}>
            <input
                type="radio"
                name={name || id}
                value={typeof value === 'string' ? value : ''}
                checked={!!checked}
                onChange={() => setData({ [id]: value })}
                style={{ marginRight: '6px' }}
            />
            <label style={{ margin: 0, fontWeight: 400 }}>{label}</label>
            {tooltip && <span title={tooltip} style={{ marginLeft: '4px', cursor: 'help', color: '#888' }}>ⓘ</span>}
        </div>
    );
}

export default React.memo(DynamicRadioButton);
