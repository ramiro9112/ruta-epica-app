import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Términos y condiciones'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Section(
            title: 'Aceptación de los términos',
            content:
                'Al acceder y utilizar la aplicación Ruta Épica, usted acepta quedar vinculado por los presentes Términos y Condiciones de Uso. Si no está de acuerdo con alguno de estos términos, le pedimos que no utilice nuestros servicios. Ruta Épica se reserva el derecho de modificar estos términos en cualquier momento, notificando a los usuarios a través de la aplicación.',
          ),
          _Section(
            title: 'Descripción del servicio',
            content:
                'Ruta Épica es una agencia de viajes colombiana que ofrece paquetes turísticos nacionales e internacionales, incluyendo tiquetes aéreos, alojamiento, traslados y actividades. A través de nuestra aplicación, los usuarios pueden explorar destinos, consultar paquetes disponibles y realizar reservas de viaje. Todos los servicios están sujetos a disponibilidad.',
          ),
          _Section(
            title: 'Registro y cuenta de usuario',
            content:
                'Para acceder a la funcionalidad completa de la aplicación, el usuario deberá crear una cuenta proporcionando información veraz y actualizada. El usuario es responsable de mantener la confidencialidad de sus credenciales de acceso. Ruta Épica no será responsable por el uso no autorizado de su cuenta. El usuario se compromete a notificar de inmediato cualquier uso no autorizado de su cuenta.',
          ),
          _Section(
            title: 'Reservas y pagos',
            content:
                'Las reservas realizadas a través de Ruta Épica están sujetas a confirmación por parte de un asesor especializado. El proceso de pago se gestiona directamente con el asesor asignado, quien le informará los medios disponibles: transferencia bancaria, PSE, tarjetas de crédito/débito o efectivo a través de corresponsales bancarios.\n\nLa reserva queda confirmada únicamente cuando se recibe el pago total o el abono acordado. Los precios publicados en la aplicación son referenciales y pueden variar según disponibilidad, temporada o condiciones del proveedor.',
          ),
          _Section(
            title: 'Política de cancelación y reembolsos',
            content:
                '• Cancelaciones con más de 30 días de anticipación al viaje: reembolso del 100% del valor pagado.\n\n• Cancelaciones entre 15 y 30 días antes del viaje: reembolso del 50% del valor pagado.\n\n• Cancelaciones con menos de 15 días de anticipación: no habrá lugar a reembolso, salvo casos de fuerza mayor debidamente documentados.\n\nPara solicitar una cancelación, el usuario debe contactar a Ruta Épica a través de los canales oficiales de soporte. Los reembolsos aprobados se procesarán en un plazo de 10 días hábiles.',
          ),
          _Section(
            title: 'Responsabilidades y limitaciones',
            content:
                'Ruta Épica actúa como intermediario entre el viajero y los prestadores de servicios turísticos (aerolíneas, hoteles, operadores locales). En caso de incumplimiento por parte de terceros proveedores, Ruta Épica gestionará la solución del inconveniente, pero no podrá ser considerada directamente responsable por las actuaciones de dichos prestadores.\n\nRuta Épica no se hace responsable por:\n• Cancelaciones o cambios por parte de aerolíneas u hoteles.\n• Eventos de fuerza mayor (desastres naturales, pandemias, huelgas).\n• Pérdida de documentos, equipaje u objetos personales durante el viaje.\n• Accidentes o lesiones ocurridas durante actividades turísticas.',
          ),
          _Section(
            title: 'Documentos y visas',
            content:
                'Es responsabilidad exclusiva del viajero verificar y gestionar los requisitos de documentación necesarios para viajar al destino elegido, incluyendo pasaporte vigente, visas, vacunas requeridas y demás exigencias migratorias. Ruta Épica puede brindar información orientativa, pero no garantiza la exactitud ni vigencia de los requisitos, que pueden cambiar sin previo aviso por disposición de los países de destino.',
          ),
          _Section(
            title: 'Protección de datos personales',
            content:
                'Ruta Épica recopila y trata datos personales de conformidad con la Ley 1581 de 2012 (Ley de Protección de Datos Personales de Colombia) y demás normas concordantes. Los datos del usuario serán utilizados exclusivamente para:\n• Gestionar reservas y servicios contratados.\n• Enviar información relevante sobre el viaje.\n• Mejorar la experiencia del usuario en la aplicación.\n• Enviar comunicaciones comerciales con previo consentimiento.\n\nEl usuario podrá ejercer sus derechos de acceso, rectificación, cancelación y oposición (derechos ARCO) enviando un correo a agenciarutaepica@gmail.com.',
          ),
          _Section(
            title: 'Propiedad intelectual',
            content:
                'Todos los contenidos de la aplicación Ruta Épica, incluyendo pero no limitados a textos, imágenes, logotipos, diseños, código fuente y materiales multimedia, son propiedad de Ruta Épica o se usan bajo licencia. Queda prohibida su reproducción, distribución o uso comercial sin autorización expresa y por escrito de Ruta Épica.',
          ),
          _Section(
            title: 'Modificaciones al servicio',
            content:
                'Ruta Épica se reserva el derecho de modificar, suspender o discontinuar, temporal o permanentemente, cualquier aspecto del servicio en cualquier momento, con o sin previo aviso. El uso continuado de la aplicación después de dichas modificaciones constituye su aceptación de los cambios.',
          ),
          _Section(
            title: 'Ley aplicable y jurisdicción',
            content:
                'Los presentes Términos y Condiciones se rigen por las leyes de la República de Colombia. Cualquier controversia que surja en relación con estos términos será sometida a la jurisdicción de los tribunales competentes de la ciudad de Bogotá D.C., Colombia, salvo que las partes acuerden un mecanismo alternativo de resolución de conflictos.',
          ),
          _Section(
            title: 'Contacto',
            content:
                'Para cualquier consulta, reclamación o solicitud relacionada con estos términos, puede contactarnos a través de:\n\n• WhatsApp: +57 305 239 4904\n• Correo electrónico: agenciarutaepica@gmail.com\n• Horario de atención: lunes a sábado, 8:00 a.m. – 6:00 p.m.',
          ),
          SizedBox(height: 12),
          _LastUpdated(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.deepBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.darkText,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastUpdated extends StatelessWidget {
  const _LastUpdated();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Última actualización: enero 2025',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.darkGray,
        ),
      ),
    );
  }
}
