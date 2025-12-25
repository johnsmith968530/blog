import React, { useState, useMemo } from 'react';

// The Hat tile vertices (normalized)
const HAT_SHAPE = [
  [0, 0],
  [1, 0],
  [1.5, Math.sqrt(3)/2],
  [1, Math.sqrt(3)],
  [1.5, 1.5*Math.sqrt(3)],
  [1, 2*Math.sqrt(3)],
  [0, 2*Math.sqrt(3)],
  [-0.5, 1.5*Math.sqrt(3)],
  [-1, 2*Math.sqrt(3)],
  [-1.5, 1.5*Math.sqrt(3)],
  [-1, Math.sqrt(3)],
  [-0.5, Math.sqrt(3)/2],
  [-1, 0],
];

// Cat silhouette path for masking
const catPath = (cx, cy, size) => {
  const s = size;
  return `
    M ${cx - s*0.4} ${cy + s*0.5}
    Q ${cx - s*0.5} ${cy + s*0.3} ${cx - s*0.45} ${cy + s*0.1}
    Q ${cx - s*0.5} ${cy - s*0.1} ${cx - s*0.4} ${cy - s*0.2}
    L ${cx - s*0.45} ${cy - s*0.45}
    L ${cx - s*0.25} ${cy - s*0.25}
    Q ${cx - s*0.15} ${cy - s*0.35} ${cx} ${cy - s*0.38}
    Q ${cx + s*0.15} ${cy - s*0.35} ${cx + s*0.25} ${cy - s*0.25}
    L ${cx + s*0.45} ${cy - s*0.45}
    L ${cx + s*0.4} ${cy - s*0.2}
    Q ${cx + s*0.5} ${cy - s*0.1} ${cx + s*0.45} ${cy + s*0.1}
    Q ${cx + s*0.5} ${cy + s*0.3} ${cx + s*0.4} ${cy + s*0.5}
    Q ${cx + s*0.2} ${cy + s*0.55} ${cx} ${cy + s*0.5}
    Q ${cx - s*0.2} ${cy + s*0.55} ${cx - s*0.4} ${cy + s*0.5}
    Z
  `;
};

// Check if point is inside cat silhouette
const isInsideCat = (x, y, cx, cy, size) => {
  const s = size;
  const relX = (x - cx) / s;
  const relY = (y - cy) / s;
  
  // Simplified cat shape check using geometric regions
  // Body ellipse
  const bodyCheck = (relX * relX) / 0.2 + ((relY - 0.15) * (relY - 0.15)) / 0.15 < 1;
  
  // Head circle
  const headCheck = relX * relX + (relY + 0.1) * (relY + 0.1) < 0.12;
  
  // Left ear triangle
  const leftEar = relX > -0.45 && relX < -0.2 && 
                  relY < -0.2 && relY > -0.5 &&
                  relY < -relX - 0.5 && relY < relX + 0.1;
  
  // Right ear triangle  
  const rightEar = relX < 0.45 && relX > 0.2 && 
                   relY < -0.2 && relY > -0.5 &&
                   relY < relX - 0.5 && relY < -relX + 0.1;
  
  return bodyCheck || headCheck || leftEar || rightEar;
};

// Generate tile positions in a hex-like grid pattern
const generateTilePositions = (width, height, scale) => {
  const positions = [];
  const tileWidth = 3 * scale;
  const tileHeight = 2 * Math.sqrt(3) * scale;
  
  for (let row = -2; row < height / tileHeight + 2; row++) {
    for (let col = -2; col < width / tileWidth + 2; col++) {
      const offsetX = (row % 2) * tileWidth * 0.5;
      const x = col * tileWidth + offsetX;
      const y = row * tileHeight * 0.75;
      
      // Add tile with rotation variations
      const rotation = ((row + col) % 6) * 60;
      const mirror = (row + col) % 3 === 0;
      
      positions.push({ x, y, rotation, mirror });
    }
  }
  return positions;
};

// Transform hat vertices
const transformHat = (x, y, scale, rotation, mirror) => {
  return HAT_SHAPE.map(([px, py]) => {
    let tx = px * scale;
    let ty = py * scale;
    
    if (mirror) tx = -tx;
    
    const rad = (rotation * Math.PI) / 180;
    const rx = tx * Math.cos(rad) - ty * Math.sin(rad);
    const ry = tx * Math.sin(rad) + ty * Math.cos(rad);
    
    return [rx + x, ry + y];
  });
};

const HatCatTShirt = () => {
  const [catColor, setCatColor] = useState('#FF6B35');
  const [bgColor, setBgColor] = useState('#2E4057');
  const [outlineColor, setOutlineColor] = useState('#1a1a2e');
  const [tshirtColor, setTshirtColor] = useState('#1a1a2e');
  const [scale, setScale] = useState(12);
  
  const width = 400;
  const height = 500;
  const centerX = width / 2;
  const centerY = height / 2 - 20;
  const catSize = 280;
  
  const tiles = useMemo(() => {
    const positions = generateTilePositions(width, height, scale);
    return positions.map((pos, i) => {
      const vertices = transformHat(pos.x, pos.y, scale, pos.rotation, pos.mirror);
      
      // Calculate tile center
      const tileCenterX = vertices.reduce((sum, v) => sum + v[0], 0) / vertices.length;
      const tileCenterY = vertices.reduce((sum, v) => sum + v[1], 0) / vertices.length;
      
      const isInCat = isInsideCat(tileCenterX, tileCenterY, centerX, centerY, catSize);
      
      return {
        id: i,
        vertices,
        isInCat,
        path: vertices.map((v, j) => `${j === 0 ? 'M' : 'L'} ${v[0]} ${v[1]}`).join(' ') + ' Z'
      };
    });
  }, [scale, centerX, centerY, catSize]);
  
  return (
    <div className="flex flex-col items-center p-4 min-h-screen bg-gray-900">
      <h1 className="text-2xl font-bold text-white mb-4">🎨 Hat Tile Cat T-Shirt Design</h1>
      
      <div className="flex flex-wrap gap-4 mb-6 justify-center">
        <label className="flex flex-col items-center text-white text-sm">
          Cat Color
          <input 
            type="color" 
            value={catColor} 
            onChange={(e) => setCatColor(e.target.value)}
            className="w-12 h-8 cursor-pointer rounded mt-1"
          />
        </label>
        <label className="flex flex-col items-center text-white text-sm">
          Background Tiles
          <input 
            type="color" 
            value={bgColor} 
            onChange={(e) => setBgColor(e.target.value)}
            className="w-12 h-8 cursor-pointer rounded mt-1"
          />
        </label>
        <label className="flex flex-col items-center text-white text-sm">
          Tile Outline
          <input 
            type="color" 
            value={outlineColor} 
            onChange={(e) => setOutlineColor(e.target.value)}
            className="w-12 h-8 cursor-pointer rounded mt-1"
          />
        </label>
        <label className="flex flex-col items-center text-white text-sm">
          T-Shirt Color
          <input 
            type="color" 
            value={tshirtColor} 
            onChange={(e) => setTshirtColor(e.target.value)}
            className="w-12 h-8 cursor-pointer rounded mt-1"
          />
        </label>
        <label className="flex flex-col items-center text-white text-sm">
          Tile Size: {scale}
          <input 
            type="range" 
            min="8" 
            max="20" 
            value={scale} 
            onChange={(e) => setScale(Number(e.target.value))}
            className="w-24 mt-1"
          />
        </label>
      </div>
      
      {/* T-Shirt mockup */}
      <svg width="450" height="580" viewBox="0 0 450 580" className="drop-shadow-2xl">
        <defs>
          <clipPath id="designArea">
            <rect x="25" y="40" width={width} height={height} rx="8"/>
          </clipPath>
          
          {/* T-shirt shape */}
          <clipPath id="tshirtShape">
            <path d={`
              M 100 0
              L 175 0
              Q 225 20 225 60
              Q 225 20 275 0
              L 350 0
              L 420 80
              L 380 100
              L 360 80
              L 360 560
              Q 360 580 340 580
              L 110 580
              Q 90 580 90 560
              L 90 80
              L 70 100
              L 30 80
              Z
            `}/>
          </clipPath>
        </defs>
        
        {/* T-shirt body */}
        <g clipPath="url(#tshirtShape)">
          <rect x="0" y="0" width="450" height="580" fill={tshirtColor}/>
          
          {/* Design area */}
          <g transform="translate(25, 40)" clipPath="url(#designArea)">
            {/* Background */}
            <rect x="0" y="0" width={width} height={height} fill={tshirtColor}/>
            
            {/* Hat tiles */}
            {tiles.map(tile => (
              <path
                key={tile.id}
                d={tile.path}
                fill={tile.isInCat ? catColor : bgColor}
                stroke={outlineColor}
                strokeWidth="0.5"
                opacity={tile.isInCat ? 1 : 0.6}
              />
            ))}
            
            {/* Cat face details */}
            <g opacity="0.9">
              {/* Eyes */}
              <ellipse cx={centerX - 35} cy={centerY - 45} rx="12" ry="16" fill={tshirtColor}/>
              <ellipse cx={centerX + 35} cy={centerY - 45} rx="12" ry="16" fill={tshirtColor}/>
              <ellipse cx={centerX - 35} cy={centerY - 42} rx="6" ry="10" fill="#2dd4bf"/>
              <ellipse cx={centerX + 35} cy={centerY - 42} rx="6" ry="10" fill="#2dd4bf"/>
              <ellipse cx={centerX - 35} cy={centerY - 42} rx="3" ry="8" fill={tshirtColor}/>
              <ellipse cx={centerX + 35} cy={centerY - 42} rx="3" ry="8" fill={tshirtColor}/>
              
              {/* Nose */}
              <path 
                d={`M ${centerX} ${centerY - 10} L ${centerX - 8} ${centerY + 5} L ${centerX + 8} ${centerY + 5} Z`}
                fill="#ff9999"
              />
              
              {/* Mouth */}
              <path 
                d={`M ${centerX} ${centerY + 5} Q ${centerX - 15} ${centerY + 25} ${centerX - 25} ${centerY + 15}`}
                fill="none" 
                stroke={tshirtColor} 
                strokeWidth="3"
                strokeLinecap="round"
              />
              <path 
                d={`M ${centerX} ${centerY + 5} Q ${centerX + 15} ${centerY + 25} ${centerX + 25} ${centerY + 15}`}
                fill="none" 
                stroke={tshirtColor} 
                strokeWidth="3"
                strokeLinecap="round"
              />
              
              {/* Whiskers */}
              {[-1, 1].map(side => (
                <g key={side}>
                  <line 
                    x1={centerX + side * 25} y1={centerY} 
                    x2={centerX + side * 70} y2={centerY - 15}
                    stroke={tshirtColor} strokeWidth="2" strokeLinecap="round"
                  />
                  <line 
                    x1={centerX + side * 25} y1={centerY + 10} 
                    x2={centerX + side * 70} y2={centerY + 10}
                    stroke={tshirtColor} strokeWidth="2" strokeLinecap="round"
                  />
                  <line 
                    x1={centerX + side * 25} y1={centerY + 20} 
                    x2={centerX + side * 70} y2={centerY + 35}
                    stroke={tshirtColor} strokeWidth="2" strokeLinecap="round"
                  />
                </g>
              ))}
            </g>
          </g>
        </g>
        
        {/* T-shirt outline */}
        <path 
          d={`
            M 100 0
            L 175 0
            Q 225 20 225 60
            Q 225 20 275 0
            L 350 0
            L 420 80
            L 380 100
            L 360 80
            L 360 560
            Q 360 580 340 580
            L 110 580
            Q 90 580 90 560
            L 90 80
            L 70 100
            L 30 80
            Z
          `}
          fill="none"
          stroke="#333"
          strokeWidth="2"
        />
        
        {/* Collar */}
        <ellipse cx="225" cy="50" rx="50" ry="20" fill="none" stroke="#333" strokeWidth="2"/>
      </svg>
      
      <p className="text-gray-400 mt-4 text-sm text-center max-w-md">
        Each tile is the famous "Hat" einstein tile. Adjust colors and tile size to customize your design!
      </p>
    </div>
  );
};

export default HatCatTShirt;
