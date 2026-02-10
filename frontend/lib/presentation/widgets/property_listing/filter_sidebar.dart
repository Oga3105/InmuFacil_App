import 'package:flutter/material.dart';

class FilterSidebar extends StatelessWidget {
  const FilterSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF0F172A);
    const primaryBlue = Color(0xFF2563EB); // User Brand Blue

    return Container(
      width: 300,
      padding: const EdgeInsets.only(right: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Box
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: navyColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: primaryBlue,
                      ),
                      child: const Text('Limpiar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                
                // Price Range
                _buildSectionTitle('Rango de Precio'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildInput('Min')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildInput('Max')),
                  ],
                ),

                const SizedBox(height: 24),

                // Rooms
                _buildSectionTitle('Habitaciones'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRoomButton('1', false),
                    const SizedBox(width: 8),
                    _buildRoomButton('2', false),
                    const SizedBox(width: 8),
                    _buildRoomButton('3+', true), // Selected example
                    const SizedBox(width: 8),
                    _buildRoomButton('4+', false),
                  ],
                ),

                const SizedBox(height: 24),

                // Property Type
                _buildSectionTitle('Tipo de Vivienda'),
                const SizedBox(height: 8),
                _buildCheckbox('Piso', true),
                _buildCheckbox('Ático', false),
                _buildCheckbox('Dúplex', false),

                const SizedBox(height: 24),

                // Extras
                _buildSectionTitle('Extras'),
                const SizedBox(height: 8),
                _buildCheckbox('Terraza', false),
                _buildCheckbox('Ascensor', false),
                _buildCheckbox('Garaje', false),
                _buildCheckbox('Piscina', false),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Verified Toggle
                Row(
                  children: [
                    const Icon(Icons.verified_user, color: Color(0xFF16A34A), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Verificado InmuFácil',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                    const Spacer(),
                    Switch(
                      value: false, 
                      onChanged: (val) {},
                      activeColor: const Color(0xFF16A34A),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Promo Banner
          Container(
            padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(
              color: navyColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vende directo.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sin comisiones, sin intermediarios. Todo legal, todo seguro.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {},
                  child: Row(
                    children: [
                      Text(
                        'Saber más',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                       Icon(Icons.arrow_forward, size: 14, color: primaryBlue),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInput(String placeholder) {
    return TextField(
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildRoomButton(String label, bool isSelected) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildCheckbox(String label, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: isChecked,
              onChanged: (val) {},
              activeColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
