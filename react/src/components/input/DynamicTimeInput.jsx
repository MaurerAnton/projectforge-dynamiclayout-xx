import React from 'react';
import DynamicLayoutContext from '../../context';

function DynamicTimeInput({ id, label }) {
    const { data, setData } = React.useContext(DynamicLayoutContext);
    const value = data && data[id];

    return (
        <div style={{ marginBottom: '12px' }}>
            {label && <label htmlFor={id} style={{ display: 'block', marginBottom: '4px', fontWeight: 500 }}>{label}</label>}
            <input
                type="time"
                id={id}
                value={value || ''}
                onChange={(e) => setData({ [id]: e.target.value })}
                style={{
                    width: '100%',
                    padding: '6px 12px',
                    fontSize: '1rem',
                    border: '1px solid #ced4da',
                    borderRadius: '4px',
                }}
            />
        </div>
    );
}

export default React.memo(DynamicTimeInput);
