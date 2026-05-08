import React from 'react';
import DynamicLayoutContext from '../../context';

function DynamicReadonlyField({ id, label, value, canCopy, coverUp, tooltip }) {
    const { data } = React.useContext(DynamicLayoutContext);
    let displayValue = value;
    if (!displayValue && id) {
        displayValue = data && data[id];
    }
    if (coverUp && displayValue) {
        displayValue = '••••••••';
    }

    return (
        <div style={{ marginBottom: '12px' }}>
            {label && <label style={{ display: 'block', marginBottom: '2px', fontWeight: 500, color: '#6c757d' }}>{label}</label>}
            <div style={{
                padding: '6px 12px',
                backgroundColor: '#e9ecef',
                borderRadius: '4px',
                fontSize: '1rem',
            }}>
                {displayValue || '—'}
                {canCopy && displayValue && (
                    <button
                        type="button"
                        onClick={() => navigator.clipboard?.writeText(String(displayValue))}
                        style={{
                            marginLeft: '8px',
                            border: 'none',
                            background: 'none',
                            cursor: 'pointer',
                            color: '#0d6efd',
                            fontSize: '0.85rem',
                        }}
                    >
                        Copy
                    </button>
                )}
            </div>
            {tooltip && <small style={{ color: '#888', display: 'block', marginTop: '2px' }}>{tooltip}</small>}
        </div>
    );
}

export default React.memo(DynamicReadonlyField);
