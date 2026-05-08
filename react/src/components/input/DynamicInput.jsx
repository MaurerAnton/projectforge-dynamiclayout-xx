import React from 'react';
import DynamicLayoutContext from '../../context';

function DynamicInput({ id, label, required, maxLength, focus, placeholder, tooltip, type, additionalLabel }) {
    const { data, setData, validationErrors } = React.useContext(DynamicLayoutContext);
    const value = data && data[id];
    const error = validationErrors && validationErrors.find(e => e.fieldId === id);

    return (
        <div style={{ marginBottom: '12px' }}>
            {label && (
                <label htmlFor={id} style={{ display: 'block', marginBottom: '4px', fontWeight: 500 }}>
                    {label}
                    {required && <span style={{ color: '#dc3545', marginLeft: '2px' }}>*</span>}
                    {additionalLabel && <span style={{ color: '#888', fontSize: '0.85em', marginLeft: '4px' }}>{additionalLabel}</span>}
                </label>
            )}
            <input
                id={id}
                type={type || 'text'}
                value={value || ''}
                maxLength={maxLength || undefined}
                autoFocus={focus}
                placeholder={placeholder}
                onChange={(e) => setData({ [id]: e.target.value })}
                style={{
                    width: '100%',
                    padding: '6px 12px',
                    fontSize: '1rem',
                    border: `1px solid ${error ? '#dc3545' : '#ced4da'}`,
                    borderRadius: '4px',
                    boxSizing: 'border-box',
                }}
            />
            {tooltip && <small style={{ color: '#888', display: 'block', marginTop: '2px' }}>{tooltip}</small>}
            {error && <small style={{ color: '#dc3545', display: 'block', marginTop: '2px' }}>{error.message}</small>}
        </div>
    );
}

export default React.memo(DynamicInput, (prev, next) => prev.id === next.id && prev.data === next.data);
