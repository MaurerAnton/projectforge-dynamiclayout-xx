import React from 'react';
import DynamicLayoutContext from '../context';

const colorMap = {
    primary: '#cfe2ff',
    secondary: '#e2e3e5',
    success: '#d1e7dd',
    danger: '#f8d7da',
    warning: '#fff3cd',
    info: '#cff4fc',
    light: '#fefefe',
    dark: '#d3d3d4',
};

const textColorMap = {
    primary: '#084298',
    secondary: '#41464b',
    success: '#0f5132',
    danger: '#842029',
    warning: '#664d03',
    info: '#055160',
    light: '#000',
    dark: '#141619',
};

function DynamicAlert({ message, title, color, id, markdown, icon }) {
    const { data } = React.useContext(DynamicLayoutContext);
    const resolvedMessage = (id && data && data[id]) || message;

    if (!resolvedMessage) return null;

    return (
        <div style={{
            padding: '16px',
            backgroundColor: colorMap[color] || colorMap.info,
            color: textColorMap[color] || textColorMap.info,
            borderRadius: '6px',
            border: `1px solid ${colorMap[color] || colorMap.info}`,
            marginBottom: '16px',
        }}>
            {title && <h4 style={{ margin: '0 0 8px 0', fontSize: '1rem' }}>{title}</h4>}
            <div style={{ margin: 0 }}>{resolvedMessage}</div>
        </div>
    );
}

export default React.memo(DynamicAlert);
